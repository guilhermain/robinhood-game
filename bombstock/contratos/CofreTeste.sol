// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address para, uint256 v) external returns (bool);
    function transferFrom(address de, address para, uint256 v) external returns (bool);
    function balanceOf(address quem) external view returns (uint256);
}

/// SOMENTE TESTNET. Cofre que paga sem prova nenhuma: o jogador diz quanto
/// minerou e recebe. Isso e drenavel de proposito — na testnet os tokens nao
/// valem nada e o objetivo e ver o ciclo inteiro funcionando.
///
/// Na mainnet quem vale e o RewardVault.sol, que exige prova de Merkle de uma
/// raiz publicada por um servidor autoritativo. NAO DEPLOYAR ISTO NA MAINNET.
contract CofreTeste {
    address public dono;
    address public bstock;
    uint256 public tetoPorSaque = 1000e18;   // trava boba, so para nao secar
    uint256 public precoPacote1;             // em $BSTOCK, por heroi
    uint256 public precoMina;

    mapping(address => uint256) public sacadoPor;
    mapping(address => uint256) public pacotesComprados;
    mapping(address => uint256) public minasCompradas;

    event Sacado(address indexed jogador, address indexed token, uint256 valor);
    event PacoteComprado(address indexed jogador, uint256 qtd, uint256 custo);
    event MinaComprada(address indexed jogador, string mina, uint256 custo);

    modifier soDono() { require(msg.sender == dono, "so o dono"); _; }

    constructor(address _bstock, uint256 _precoPacote1, uint256 _precoMina) {
        dono = msg.sender; bstock = _bstock;
        precoPacote1 = _precoPacote1; precoMina = _precoMina;
    }

    function setPrecos(uint256 p1, uint256 pm) external soDono { precoPacote1 = p1; precoMina = pm; }
    function setTeto(uint256 t) external soDono { tetoPorSaque = t; }

    /// O jogador paga em $BSTOCK. Precisa ter dado approve antes.
    function comprarPacote(uint256 qtd) external {
        require(qtd == 1 || qtd == 5 || qtd == 10, "pacote invalido");
        uint256 custo = precoPacote1 * qtd;
        require(IERC20(bstock).transferFrom(msg.sender, address(this), custo), "pagamento falhou");
        pacotesComprados[msg.sender] += qtd;
        emit PacoteComprado(msg.sender, qtd, custo);
    }

    function comprarMina(string calldata mina) external {
        require(IERC20(bstock).transferFrom(msg.sender, address(this), precoMina), "pagamento falhou");
        minasCompradas[msg.sender] += 1;
        emit MinaComprada(msg.sender, mina, precoMina);
    }

    /// Converte o que foi minerado em $BSTOCK ao preco informado pelo operador.
    /// Na mainnet quem faz isso e o keeper, vendendo a acao no mercado e
    /// comprando $BSTOCK — aqui e simplificado para provar o caminho.
    /// taxaBstock: quantos $BSTOCK por unidade de acao, em 1e18.
    mapping(address => uint256) public taxaBstock;

    function setTaxaBstock(address token, uint256 taxa) external soDono {
        taxaBstock[token] = taxa;
    }

    function sacarComoBstock(address token, uint256 valor) external {
        require(valor <= tetoPorSaque, "acima do teto");
        uint256 taxa = taxaBstock[token];
        require(taxa > 0, "sem taxa para este token");
        uint256 saida = valor * taxa / 1e18;
        require(IERC20(bstock).balanceOf(address(this)) >= saida, "cofre sem bstock");
        sacadoPor[msg.sender] += valor;
        IERC20(bstock).transfer(msg.sender, saida);
        emit Sacado(msg.sender, bstock, saida);
    }

    /// Saque livre. Existe so para provar o caminho na testnet.
    function sacar(address token, uint256 valor) external {
        require(valor <= tetoPorSaque, "acima do teto");
        require(IERC20(token).balanceOf(address(this)) >= valor, "cofre vazio");
        sacadoPor[msg.sender] += valor;
        IERC20(token).transfer(msg.sender, valor);
        emit Sacado(msg.sender, token, valor);
    }

    function recolher(address token, uint256 valor) external soDono {
        IERC20(token).transfer(dono, valor);
    }
}
