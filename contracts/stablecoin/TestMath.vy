# @version 0.3.7

coin_price1: public(uint256)
coin_price2: public(decimal)
coin_price3: public(uint256)
coin_price4: public(uint256)

@external
def __init__():
    # Uses uint256 so rounds down to zero
    self.coin_price1 = 69 / 100
    # Make it clear you want decimals by declaring so.
    self.coin_price2 = 69.0 / 100.0
    # This one works from left to right, so it begins with zero and therefore end up with zero.
    self.coin_price3 = 69 / 100 * 10 ** 18
    # Make a big number to create a decimal equivalent. Prone to overflow. 
    self.coin_price4 = 10 ** 18 * 69 / 100

# Numerator gets too big at <self.coin_price4 ** 5> and never gets to the correct </10**18> part.
@external
@view
def test_overflow() -> uint256:
    return self.coin_price4 ** 5 / 10 ** 18 