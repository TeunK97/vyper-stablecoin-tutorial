import pytest
from ape import Contract, chain, networks
from eip712.messages import EIP712Message


@pytest.fixture(scope="session")
def Permit(chain, token):
    class Permit(EIP712Message):
        _name_: "string" = "one-buck"
        _version_: "string" = "1.0"
        _chainId_: "uint256" = chain.chain_id
        _verifyingContract_: "address" = token.address

        owner: "address"
        spender: "address"
        value: "uint256"
        nonce: "uint256"
        deadline: "uint256"
    return Permit

@pytest.fixture(scope="module")
def is_forked():
    if "fork" in networks.active_provider.config:
        return True
    else:
        return False

@pytest.fixture(scope="module")
def owner(accounts, is_forked):
    if is_forked:
        return accounts['0x32d03db62e464c9168e41028ffa6e9a05d8c6451'] ## CRV whale
    else:
        return accounts[0]

@pytest.fixture(scope="module")
def receiver(accounts, is_forked):
    if is_forked:
        return accounts["0x9b44473e223f8a3c047ad86f387b80402536b029"]
    else:
        return accounts[1]

@pytest.fixture(scope="module")
def alice(accounts, is_forked):
    if is_forked:
        return accounts["0xF89501B77b2FA6329F94F5A05FE84cEbb5c8b1a0"]
    else:
        return accounts[2]

@pytest.fixture(scope="module")
def token(owner, project):
    return owner.deploy(project.Token)

@pytest.fixture(scope="module")
def collateral(owner, project, is_forked):
    if is_forked:
        return Contract("0xD533a949740bb3306d119CC777fa900bA034cd52")
    else:
        return owner.deploy(project.Collateral)

@pytest.fixture(scope="module")
def minter(owner, project, token, collateral):
    minter = project.Minter.deploy(token.address, collateral.address, sender=owner)
    token.setMinter(minter.address, sender=owner)
    collateral.approve(minter.address, collateral.balanceOf(owner.address), sender=owner)
    return minter

