/// end.sol -- global settlement engine

// Copyright (C) 2018 Rain <rainbreak@riseup.net>
// Copyright (C) 2018 Lev Livnev <lev@liv.nev.org.uk>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

contract VatLike {
    struct Ilk {
        uint256 rate;
        uint256 Art;
        uint256 spot;
        uint256 line;
        uint256 dust;
    }
    struct Urn {
        uint256 ink;
        uint256 art;
    }
    function sin(bytes32) public view returns (uint);
    function dai(bytes32 lad) public returns (uint256);
    function ilks(bytes32 ilk) public returns (Ilk memory);
    function urns(bytes32 ilk, bytes32 urn) public returns (Urn memory);
    function move(bytes32 src, bytes32 dst, int256 rad) public;
    function flux(bytes32 ilk, bytes32 src, bytes32 dst, int256 rad) public;
    function tune(bytes32 i, bytes32 u, bytes32 v, bytes32 w, int256 dink, int256 dart) public;
    function grab(bytes32 i, bytes32 u, bytes32 v, bytes32 w, int256 dink, int256 dart) public;
    function heal(bytes32 u, bytes32 v, int256 rad) public;
    function cage() public;
}
contract CatLike {
    struct Ilk {
        address flip;  // Liquidator
        uint256 chop;  // Liquidation Penalty   [ray]
        uint256 lump;  // Liquidation Quantity  [wad]
    }
    function ilks(bytes32) public returns (Ilk memory);
    function cage() public;
}
contract VowLike {
    function Joy() public returns (uint256);
    function Woe() public returns (uint256);
    function hump() public returns (uint256);
    function heal(uint256 wad) public;
}
contract Flippy {
    struct Bid {
        uint256 bid;
        uint256 lot;
        address guy;
        uint48  tic;
        uint48  end;
        bytes32 urn;
        address gal;
        uint256 tab;
    }
    function cage() public;
    function bids(uint id) public view returns (Bid memory);
    function yank(uint id) public;
}

contract End {

    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) public auth { wards[guy] = 1; }
    function deny(address guy) public auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- Data ---
    VatLike  public vat;
    CatLike  public cat;
    VowLike  public vow;
    uint256  public live;

    mapping (address => uint256)                      public dai;
    mapping (bytes32 => uint256)                      public tags;
    mapping (bytes32 => uint256)                      public fixs;
    mapping (bytes32 => mapping (bytes32 => uint256)) public bags;

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Helpers ---
    function b32(address a) internal pure returns (bytes32 b) {
        b = bytes32(bytes20(a));
    }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
    function sub(uint x, uint y) internal pure returns (int z) {
        z = int(x - y);
        require(x < y || z >= 0);
        require(x > y || z <= 0);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
    }

    uint constant RAY = 10 ** 27;
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / RAY;
    }
    function u2i(uint x) internal pure returns (int y) {
        y = int(x);
        require(y >= 0);
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        if (x > y) { z = y; } else { z = x; }
    }
    function min(int x, int y) internal pure returns (int z) {
        if (x > y) { z = y; } else { z = x; }
    }

    // --- Administration ---
    function file(bytes32 what, address data) public auth {
        if (what == "vat") vat = VatLike(data);
        if (what == "cat") cat = CatLike(data);
        if (what == "vow") vow = VowLike(data);
    }

    // --- Settlement ---
    function cage(uint256 dump) public auth {
        require(live == 1);
        vat.cage();
        cat.cage();
        vow.heal(min(vow.Joy(), vow.Woe()));
        vat.move(b32(address(vow)), b32(address(this)), u2i(min(mul(vow.Joy(), RAY), mul(vow.hump(), dump))));
        live = 0;
    }

    function cage(bytes32 ilk, uint256 tag, uint256 fix) public auth {
        require(live == 0);
        tags[ilk] = tag;
        fixs[ilk] = fix;
        Flippy(cat.ilks(ilk).flip).cage();
    }

    function skip(bytes32 ilk, uint256 id) public {
        require(live == 0);

        address flip = cat.ilks(ilk).flip;
        Flippy.Bid memory bid = Flippy(flip).bids(id);

        VatLike.Ilk memory i = vat.ilks(ilk);
        uint256 dink = rmul(bid.lot, RAY);
        uint256 dart = mul(bid.tab, RAY) / i.rate;

        Flippy(flip).yank(id);

        vat.heal(b32(address(vow)), b32(address(vow)), min(0, sub(vat.sin(b32(address(vow))), mul(i.rate, dart))));
        vat.grab(ilk, bid.urn, b32(address(this)), b32(address(vow)), int(dink), int(dart));
    }

    function skim(bytes32 ilk, bytes32 urn) public {
        require(tags[ilk] != 0);

        VatLike.Ilk memory i = vat.ilks(ilk);
        VatLike.Urn memory u = vat.urns(ilk, urn);

        uint war = min(u.ink, rmul(rmul(u.art, i.rate), tags[ilk]));

        vat.grab(ilk, urn, b32(address(this)), b32(address(this)), -int(war), -int(u.art));
    }

    function free(bytes32 ilk) public {
        // TODO: access to bytes
        VatLike.Urn memory u = vat.urns(ilk, b32(msg.sender));
        require(u.art == 0);
        vat.grab(ilk, b32(msg.sender), b32(msg.sender), b32(msg.sender), -int(u.ink), 0);
    }

    function shop(uint256 wad) public {
        vat.heal(b32(address(this)), b32(msg.sender), int(mul(wad, RAY)));
        dai[msg.sender] = add(dai[msg.sender], wad);
    }

    function pack(bytes32 ilk) public {
        require(bags[ilk][b32(msg.sender)] == 0);
        bags[ilk][b32(msg.sender)] = add(bags[ilk][b32(msg.sender)], dai[msg.sender]);
    }

    function cash(bytes32 ilk) public {
        vat.flux(ilk, b32(address(this)), b32(msg.sender), int(rmul(bags[ilk][b32(msg.sender)], fixs[ilk])));
        bags[ilk][b32(msg.sender)]  = 0;
        dai[msg.sender]             = 0;
    }

    function vent(uint256 rad) public {
        vat.heal(b32(address(this)), b32(address(this)), u2i(rad));
    }
}
