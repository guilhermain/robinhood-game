// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(address de, address para, uint256 v) external returns (bool);
}

/// Herói do BOMBSTOCK como NFT. SOMENTE TESTNET.
///
/// O que isto conserta: hoje a raridade e os stats do herói são sorteados no
/// navegador do jogador, ou seja, ele pode editar pelo console e se dar um
/// Elon. Aqui o sorteio acontece dentro do contrato e fica gravado na chain.
///
/// SOBRE A ALEATORIEDADE — leia antes de levar para a mainnet.
/// O seed vem de blockhash, timestamp, do endereço e de um contador interno.
/// Numa chain com sequenciador único, como esta, quem opera o sequenciador
/// consegue influenciar o resultado. Para a mainnet o caminho é commit-reveal
/// em dois passos com assinatura de servidor entrando no seed — está escrito
/// no HeroNFT_v2.sol. Aqui é uma transação só, de propósito: na testnet o
/// herói não vale nada e a fricção de duas assinaturas atrapalharia o teste.
///
/// As seis raridades e as chances são as do Bombcrypto, iguais às do jogo.
contract HeroiTestnet {
    string public constant name   = "BOMBSTOCK Hero";
    string public constant symbol = "BHERO";

    address public dono;
    address public bstock;
    address public tesouro;
    uint256 public precoPorHeroi;

    // chances em base 10000, somando 10000
    uint16[6] public chances = [8287, 1036, 518, 104, 52, 3];

    struct Heroi {
        uint8  raridade;    // 0..5
        uint8  personagem;  // id do elenco
        uint8  power;
        uint8  stamina;
        uint8  speed;
        uint8  bombas;
        uint8  alcance;
        uint8  skills;      // bitmask das 7 skills
    }

    uint256 public totalSupply;
    uint256 private nonce;
    mapping(uint256 => address) public ownerOf;
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => Heroi)   public herois;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    event Transfer(address indexed de, address indexed para, uint256 indexed id);
    event Approval(address indexed dono, address indexed aprovado, uint256 indexed id);
    event ApprovalForAll(address indexed dono, address indexed operador, bool ok);
    event HeroiMintado(address indexed para, uint256 indexed id, uint8 raridade, uint8 personagem);

    modifier soDono(){ require(msg.sender==dono, "so o dono"); _; }

    constructor(address _bstock, address _tesouro, uint256 _preco){
        dono=msg.sender; bstock=_bstock; tesouro=_tesouro; precoPorHeroi=_preco;
    }

    function setPreco(uint256 p) external soDono { precoPorHeroi=p; }
    function setTesouro(address t) external soDono { tesouro=t; }

    /// Compra e mint numa transação. Pague em $BSTOCK (approve antes).
    function abrirPacote(uint256 qtd) external returns (uint256 primeiro) {
        require(qtd==1 || qtd==5 || qtd==10, "pacote invalido");
        require(IERC20(bstock).transferFrom(msg.sender, tesouro, precoPorHeroi*qtd), "pagamento falhou");

        primeiro = totalSupply + 1;
        bool garantiu = false;
        for (uint256 i=0; i<qtd; i++){
            uint256 semente = uint256(keccak256(abi.encodePacked(
                blockhash(block.number-1), block.timestamp, msg.sender, ++nonce, i)));
            uint8 rar = _raridade(semente % 10000);
            // pacote de 10 garante pelo menos um acima de comum
            if (qtd==10 && i==qtd-1 && !garantiu && rar==0) rar = 1;
            if (rar>0) garantiu = true;
            _mintar(msg.sender, rar, semente);
        }
    }

    function _raridade(uint256 rolagem) internal view returns (uint8) {
        uint256 acc;
        for (uint8 i=0;i<6;i++){
            acc += chances[i];
            if (rolagem < acc) return i;
        }
        return 0;
    }

    function _mintar(address para, uint8 rar, uint256 semente) internal {
        uint256 id = ++totalSupply;
        // faixa de stat por raridade: 1-3, 4-6, 7-9, 10-12, 13-15, 16-18
        uint8 base = uint8(1 + rar*3);
        uint8 pw = base + uint8((semente >> 8)  % 3);
        uint8 st = base + uint8((semente >> 16) % 3);
        uint8 sp = base + uint8((semente >> 24) % 3);
        uint8 bo = 1 + uint8(pw/4);
        uint8 al = 1 + uint8(st/4);
        // 0 a 2 skills, como no original
        uint8 quantas = uint8((semente >> 32) % 3);
        uint8 sk;
        for (uint8 k=0;k<quantas;k++){
            sk |= uint8(1 << ((semente >> (40 + k*8)) % 7));
        }
        herois[id] = Heroi(rar, uint8((semente >> 48) % 8), pw, st, sp, bo, al, sk);
        ownerOf[id] = para;
        balanceOf[para] += 1;
        emit Transfer(address(0), para, id);
        emit HeroiMintado(para, id, rar, herois[id].personagem);
    }

    /// Todos os heróis de uma carteira, para o jogo montar o inventário.
    function heroisDe(address quem) external view returns (uint256[] memory ids) {
        ids = new uint256[](balanceOf[quem]);
        uint256 n;
        for (uint256 i=1; i<=totalSupply && n<ids.length; i++)
            if (ownerOf[i]==quem) ids[n++]=i;
    }

    // ------------------------------------------------------------ ERC-721
    function approve(address para, uint256 id) external {
        require(ownerOf[id]==msg.sender, "nao e seu");
        getApproved[id]=para; emit Approval(msg.sender, para, id);
    }
    function setApprovalForAll(address op, bool ok) external {
        isApprovedForAll[msg.sender][op]=ok; emit ApprovalForAll(msg.sender, op, ok);
    }
    function transferFrom(address de, address para, uint256 id) public {
        require(ownerOf[id]==de, "dono errado");
        require(msg.sender==de || getApproved[id]==msg.sender || isApprovedForAll[de][msg.sender], "sem permissao");
        require(para != address(0), "endereco zero");
        delete getApproved[id];
        ownerOf[id]=para; balanceOf[de]-=1; balanceOf[para]+=1;
        emit Transfer(de, para, id);
    }
    function safeTransferFrom(address de, address para, uint256 id) external { transferFrom(de,para,id); }
    function safeTransferFrom(address de, address para, uint256 id, bytes calldata) external { transferFrom(de,para,id); }
    function supportsInterface(bytes4 i) external pure returns (bool) {
        return i==0x01ffc9a7 || i==0x80ac58cd || i==0x5b5e139f;
    }
}
