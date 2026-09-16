// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address para, uint256 valor) external returns (bool);
    function balanceOf(address quem) external view returns (uint256);
}

/// Cofre de recompensa do BOMBSTOCK.
///
/// Desenho: o jogo mede quanto cada carteira minerou de cada ação durante uma
/// época. No fim da época, quem opera publica UMA raiz de Merkle por época. O
/// jogador puxa o que é dele provando que está na árvore. O contrato nunca
/// empurra pagamento e nunca confia no cliente: ele só confere a prova.
///
/// Por que Merkle e não uma transferência por jogador: com mil jogadores seriam
/// mil transações pagas por nós. Com Merkle é uma transação nossa por época, e
/// cada jogador paga o próprio gas quando quiser sacar.
///
/// O que este contrato NÃO resolve: se a quantidade minerada foi medida por um
/// cliente que o jogador controla, a raiz publicada estará errada. A honestidade
/// do número é responsabilidade de quem publica a raiz — hoje o navegador, e é
/// por isso que isto só pode ir para a mainnet depois do servidor.
contract RewardVault {
    address public dono;
    address public operador;          // quem publica a raiz das épocas

    struct Epoca { bytes32 raiz; uint64 publicadaEm; bool congelada; }
    mapping(uint256 => Epoca) public epocas;
    uint256 public epocaAtual;

    // epoca => folha => já sacado
    mapping(uint256 => mapping(bytes32 => bool)) public sacado;

    event EpocaPublicada(uint256 indexed epoca, bytes32 raiz);
    event Sacado(uint256 indexed epoca, address indexed jogador, address indexed token, uint256 valor);
    event Recolhido(address indexed token, uint256 valor);

    error NaoAutorizado();
    error EpocaSemRaiz();
    error JaSacado();
    error ProvaInvalida();
    error SaldoInsuficiente();

    modifier soDono()     { if (msg.sender != dono)     revert NaoAutorizado(); _; }
    modifier soOperador() { if (msg.sender != operador && msg.sender != dono) revert NaoAutorizado(); _; }

    constructor(address _operador) {
        dono = msg.sender;
        operador = _operador;
    }

    function setOperador(address novo) external soDono { operador = novo; }
    function setDono(address novo) external soDono { dono = novo; }

    /// Publica a raiz de uma época. Uma época só pode ser publicada uma vez:
    /// republicar permitiria trocar a árvore e roubar de quem ainda não sacou.
    function publicarEpoca(uint256 epoca, bytes32 raiz) external soOperador {
        if (epocas[epoca].congelada) revert NaoAutorizado();
        epocas[epoca] = Epoca({raiz: raiz, publicadaEm: uint64(block.timestamp), congelada: true});
        if (epoca > epocaAtual) epocaAtual = epoca;
        emit EpocaPublicada(epoca, raiz);
    }

    /// A folha amarra época, jogador, token e valor. Trocar qualquer um deles
    /// muda a folha e derruba a prova.
    function folha(uint256 epoca, address jogador, address token, uint256 valor)
        public pure returns (bytes32)
    {
        return keccak256(bytes.concat(keccak256(abi.encode(epoca, jogador, token, valor))));
    }

    function sacar(uint256 epoca, address token, uint256 valor, bytes32[] calldata prova) external {
        Epoca memory e = epocas[epoca];
        if (e.raiz == bytes32(0)) revert EpocaSemRaiz();

        bytes32 f = folha(epoca, msg.sender, token, valor);
        if (sacado[epoca][f]) revert JaSacado();
        if (!verificar(prova, e.raiz, f)) revert ProvaInvalida();

        sacado[epoca][f] = true;
        if (IERC20(token).balanceOf(address(this)) < valor) revert SaldoInsuficiente();
        IERC20(token).transfer(msg.sender, valor);
        emit Sacado(epoca, msg.sender, token, valor);
    }

    function jaSacou(uint256 epoca, address jogador, address token, uint256 valor)
        external view returns (bool)
    {
        return sacado[epoca][folha(epoca, jogador, token, valor)];
    }

    function verificar(bytes32[] calldata prova, bytes32 raiz, bytes32 no)
        internal pure returns (bool)
    {
        bytes32 atual = no;
        for (uint256 i = 0; i < prova.length; i++) {
            bytes32 p = prova[i];
            atual = atual <= p ? keccak256(abi.encode(atual, p))
                               : keccak256(abi.encode(p, atual));
        }
        return atual == raiz;
    }

    /// Saída de emergência: o dono recolhe o que sobrou de uma época encerrada.
    function recolher(address token, uint256 valor) external soDono {
        IERC20(token).transfer(dono, valor);
        emit Recolhido(token, valor);
    }
}
