pragma solidity ^0.8.13;

/*** Maker Interfaces ***/

interface PotLike {
    function wards(address) external view returns (uint256);

    function chi() external view returns (uint256);

    function dsr() external view returns (uint256);

    function rho() external view returns (uint256);

    function pie(address) external view returns (uint256);

    function drip() external returns (uint256);

    function join(uint256) external;

    function exit(uint256) external;

    function file(bytes32, uint256) external;
}

interface GemLike {
    function approve(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;
}

interface VatLike {
    function can(address, address) external view returns (uint256);

    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function frob(
        bytes32,
        address,
        address,
        address,
        int256,
        int256
    ) external;

    function hope(address) external;

    function move(
        address,
        address,
        uint256
    ) external;
}

interface DaiJoinLike {
    function vat() external returns (VatLike);

    function dai() external returns (GemLike);

    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}
