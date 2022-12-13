<div align="center">
  <h1 align="center">Carbonable contracts</h1>
  <p align="center">
    <a href="https://discord.gg/zUy9UvB7cd">
        <img src="https://img.shields.io/badge/Discord-6666FF?style=for-the-badge&logo=discord&logoColor=white">
    </a>
    <a href="https://twitter.com/intent/follow?screen_name=Carbonable_io">
        <img src="https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white">
    </a>       
  </p>
  <h3 align="center">Carbonable contracts written in Cairo for StarkNet.</h3>
</div>

> ## ⚠️ WARNING! ⚠️
>
> This is repo contains highly experimental code.
> Expect rapid iteration.
> **Use at your own risk.**

### About

Carbonable implementation of [EIP-3525](https://eips.ethereum.org/EIPS/eip-3525) in Cairo based on [Solv-finance Solidity implementation](https://github.com/solv-finance/erc-3525).

### Project setup

#### 📦 Requirements

- [protostar](https://github.com/software-mansion/protostar)

### 🎉 Install

```bash
protostar install
```

### ⛏️ Compile

```bash
make
```

### 🌡️ Test

```bash
# Run all tests
make test

# Run only unit tests
protostar test tests/unit

# Run only integration tests
protostar test tests/integration
```

## 📄 License

**carbonable-contracts** is released under the [MIT](LICENSE).
