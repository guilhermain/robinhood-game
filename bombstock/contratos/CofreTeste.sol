// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address para, uint256 v) external returns (bool);
    function transferFrom(address de, address para, uint256 v) external returns (bool);
    function approve(address quem, uint256 v) external returns (bool);
    function balanceOf(address quem) external view returns (uint256);
}

interface IPool {
    function comprarA(uint256 entraB, uint256 minimoA) external returns (uint256);
    function cotar(uint256 entra, uint256 rEntra, uint256 rSai) external view returns (uint256);
    function reservaA() external view returns (uint112);
    function reservaB() external view returns (uint112);
    function preco() external view returns (uint256);
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

    address public pool;      // BSTOCK/USDG
    address public usdg;

    function setPool(address p, address u) external soDono { pool = p; usdg = u; }

    /// Converter e uma COMPRA de verdade: o cofre avalia a acao em USDG e vai
    /// ao pool comprar $BSTOCK com esse dinheiro. O preco sobe conforme se
    /// compra, e e isso que faz do mecanismo um buyback e nao uma entrega.
    /// Entregar $BSTOCK do proprio estoque nao geraria pressao de compra
    /// nenhuma — foi o erro da primeira versao deste contrato.
    function sacarComoBstock(address token, uint256 valor) external returns (uint256 recebido) {
        require(valor <= tetoPorSaque, "acima do teto");
        require(pool != address(0), "sem pool");
        uint256 taxa = taxaBstock[token];         // quantos USDG por unidade da acao
        require(taxa > 0, "sem taxa para este token");
        uint256 emUsdg = valor * taxa / 1e18;
        require(IERC20(usdg).balanceOf(address(this)) >= emUsdg, "cofre sem usdg");

        IERC20(usdg).approve(pool, emUsdg);
        recebido = IPool(pool).comprarA(emUsdg, 1);   // compra no mercado
        sacadoPor[msg.sender] += valor;
        IERC20(bstock).transfer(msg.sender, recebido);
        emit Sacado(msg.sender, bstock, recebido);
    }

    /// Quanto o jogador receberia hoje, para a tela mostrar antes de assinar.
    function cotacaoBstock(address token, uint256 valor) external view returns (uint256) {
        uint256 taxa = taxaBstock[token];
        if (taxa == 0 || pool == address(0)) return 0;
        uint256 emUsdg = valor * taxa / 1e18;
        return IPool(pool).cotar(emUsdg, IPool(pool).reservaB(), IPool(pool).reservaA());
    }

    /// Saque de VARIAS acoes numa transacao so. Sem isto o jogador assina uma
    /// vez por acao: com sete acoes sao sete confirmacoes seguidas, e entre
    /// elas a tela fica parada. Uma assinatura, um saque.
    function sacarVarios(address[] calldata tokens, uint256[] calldata valores) external {
        require(tokens.length == valores.length && tokens.length > 0, "listas invalidas");
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 v = valores[i];
            if (v == 0) continue;
            require(v <= tetoPorSaque, "acima do teto");
            require(IERC20(tokens[i]).balanceOf(address(this)) >= v, "cofre vazio");
            sacadoPor[msg.sender] += v;
            IERC20(tokens[i]).transfer(msg.sender, v);
            emit Sacado(msg.sender, tokens[i], v);
        }
    }

    /// Conversao em lote: uma assinatura para todas as acoes.
    function converterVarios(address[] calldata tokens, uint256[] calldata valores)
        external returns (uint256 recebido)
    {
        require(tokens.length == valores.length && tokens.length > 0, "listas invalidas");
        require(pool != address(0), "sem pool");
        uint256 emUsdg;
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 v = valores[i];
            if (v == 0) continue;
            require(v <= tetoPorSaque, "acima do teto");
            uint256 taxa = taxaBstock[tokens[i]];
            require(taxa > 0, "sem taxa para este token");
            emUsdg += v * taxa / 1e18;
            sacadoPor[msg.sender] += v;
        }
        require(emUsdg > 0, "nada a converter");
        require(IERC20(usdg).balanceOf(address(this)) >= emUsdg, "cofre sem usdg");
        IERC20(usdg).approve(pool, emUsdg);
        recebido = IPool(pool).comprarA(emUsdg, 1);
        IERC20(bstock).transfer(msg.sender, recebido);
        emit Sacado(msg.sender, bstock, recebido);
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
