// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// ERC-20 minimo, sem dependencia externa. Usado na TESTNET para o $BSTOCK e
/// para as sete acoes de mentira. Na mainnet as acoes sao os contratos reais da
/// Robinhood e o $BSTOCK sai da Pons; isto aqui nao vai para producao.
contract TokenTeste {
    string public name;
    string public symbol;
    uint8  public constant decimals = 18;
    uint256 public totalSupply;
    address public dono;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed de, address indexed para, uint256 valor);
    event Approval(address indexed dono, address indexed gastador, uint256 valor);

    modifier soDono() { require(msg.sender == dono, "so o dono"); _; }

    constructor(string memory _name, string memory _symbol, uint256 inicial) {
        name = _name; symbol = _symbol; dono = msg.sender;
        if (inicial > 0) _emitir(msg.sender, inicial);
    }

    function _emitir(address para, uint256 valor) internal {
        totalSupply += valor;
        balanceOf[para] += valor;
        emit Transfer(address(0), para, valor);
    }

    /// Na testnet qualquer um pega um punhado para testar o jogo.
    function torneira() external {
        require(balanceOf[msg.sender] < 1000e18, "ja tem o bastante");
        _emitir(msg.sender, 1000e18);
    }

    function emitir(address para, uint256 valor) external soDono { _emitir(para, valor); }

    function transfer(address para, uint256 valor) external returns (bool) {
        return _mover(msg.sender, para, valor);
    }

    function approve(address gastador, uint256 valor) external returns (bool) {
        allowance[msg.sender][gastador] = valor;
        emit Approval(msg.sender, gastador, valor);
        return true;
    }

    function transferFrom(address de, address para, uint256 valor) external returns (bool) {
        uint256 permitido = allowance[de][msg.sender];
        require(permitido >= valor, "sem permissao");
        if (permitido != type(uint256).max) allowance[de][msg.sender] = permitido - valor;
        return _mover(de, para, valor);
    }

    function _mover(address de, address para, uint256 valor) internal returns (bool) {
        require(para != address(0), "endereco zero");
        uint256 tem = balanceOf[de];
        require(tem >= valor, "saldo insuficiente");
        unchecked { balanceOf[de] = tem - valor; }
        balanceOf[para] += valor;
        emit Transfer(de, para, valor);
        return true;
    }
}
