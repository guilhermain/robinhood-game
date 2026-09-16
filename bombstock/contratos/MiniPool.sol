// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address para, uint256 v) external returns (bool);
    function transferFrom(address de, address para, uint256 v) external returns (bool);
    function balanceOf(address quem) external view returns (uint256);
}

/// Pool de produto constante (x*y=k), o mesmo modelo do Uniswap V2.
/// SOMENTE TESTNET — existe para que o $BSTOCK tenha mercado de verdade e a
/// conversao do cofre seja uma COMPRA, com impacto de preco, e nao uma entrega
/// a taxa fixa. Na mainnet o pool e o da Pons.
contract MiniPool {
    address public tokenA;      // $BSTOCK
    address public tokenB;      // USDG
    uint112 public reservaA;
    uint112 public reservaB;
    uint16  public taxaBps = 30;   // 0,3%, como o V2

    event Swap(address indexed quem, bool compraA, uint256 entrou, uint256 saiu);
    event Liquidez(uint256 a, uint256 b);

    constructor(address _a, address _b){ tokenA=_a; tokenB=_b; }

    /// Quem adiciona nao recebe LP token: na testnet o dono e unico e isso
    /// mantem o contrato pequeno.
    function adicionar(uint256 a, uint256 b) external {
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), a), "falhou A");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), b), "falhou B");
        reservaA += uint112(a); reservaB += uint112(b);
        emit Liquidez(reservaA, reservaB);
    }

    function cotar(uint256 entra, uint256 rEntra, uint256 rSai) public view returns (uint256) {
        uint256 comTaxa = entra * (10000 - taxaBps) / 10000;
        return (comTaxa * rSai) / (rEntra + comTaxa);
    }

    /// Compra tokenA (o $BSTOCK) pagando em tokenB. E isto que torna a
    /// conversao um buyback: o preco sobe conforme se compra.
    function comprarA(uint256 entraB, uint256 minimoA) external returns (uint256 saiuA) {
        saiuA = cotar(entraB, reservaB, reservaA);
        require(saiuA >= minimoA && saiuA > 0, "slippage");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), entraB), "pagamento falhou");
        reservaB += uint112(entraB);
        reservaA -= uint112(saiuA);
        IERC20(tokenA).transfer(msg.sender, saiuA);
        emit Swap(msg.sender, true, entraB, saiuA);
    }

    function venderA(uint256 entraA, uint256 minimoB) external returns (uint256 saiuB) {
        saiuB = cotar(entraA, reservaA, reservaB);
        require(saiuB >= minimoB && saiuB > 0, "slippage");
        require(IERC20(tokenA).transferFrom(msg.sender, address(this), entraA), "pagamento falhou");
        reservaA += uint112(entraA);
        reservaB -= uint112(saiuB);
        IERC20(tokenB).transfer(msg.sender, saiuB);
        emit Swap(msg.sender, false, entraA, saiuB);
    }

    /// Preco de 1 $BSTOCK em USDG, com 18 casas.
    function preco() external view returns (uint256) {
        if (reservaA == 0) return 0;
        return uint256(reservaB) * 1e18 / uint256(reservaA);
    }
}
