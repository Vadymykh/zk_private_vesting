// SPDX-License-Identifier: GPL-3.0
/*
    Copyright 2021 0KIMS association.

    This file is generated with [snarkJS](https://github.com/iden3/snarkjs).

    snarkJS is a free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    snarkJS is distributed in the hope that it will be useful, but WITHOUT
    ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
    License for more details.

    You should have received a copy of the GNU General Public License
    along with snarkJS. If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity >=0.7.0 <0.9.0;

contract VestingMerkleTreeVerifier {
    // Scalar field size
    uint256 private constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 private constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 private constant alphax  = 1746005075683362125848071177298531998858350397209371765274131756922253537573;
    uint256 private constant alphay  = 12808523499849123591054343020104811877096973804301118842708581097963798614378;
    uint256 private constant betax1  = 1496997262259530300179509492716538889038180547699628784567048534211737901539;
    uint256 private constant betax2  = 19933231677865444194192637186072430279965022753259156188228752971136507304592;
    uint256 private constant betay1  = 7131644878892762433215292770373061335088442559502546675525367369522201751088;
    uint256 private constant betay2  = 20475483963727886861700797538216328502266910770709500371648698254097849856083;
    uint256 private constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 private constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 private constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 private constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 private constant deltax1 = 13309761121783976409927829541785764523468952309286545765963034985630671692856;
    uint256 private constant deltax2 = 8279762048301389067807773853307753563424530778812180836961667510009093889950;
    uint256 private constant deltay1 = 14630923981794731849858880524248288014956329034688740884668310287978628140507;
    uint256 private constant deltay2 = 4144206086019386141370538105405936759646265466895624134878608097074097781440;

    
    uint256 private constant IC0x = 19445907501193030120961349038910474607527639826873921364343257468251669031143;
    uint256 private constant IC0y = 19621728070376397332483965392489468811462700502651136779657612659212998810424;
    
    uint256 private constant IC1x = 21492326614821662968875940425941321253527389216762441311981516521296636450534;
    uint256 private constant IC1y = 1704907477154875185652897941830375876991624605657084285708900222343180350506;
    
    uint256 private constant IC2x = 8308778935570280132965250347952677839702811812316930718058921143686411167022;
    uint256 private constant IC2y = 3782702822889624693222307756472034508058284902136320991574366957658443685439;
    
 
    // Memory data
    uint16 private constant pVk = 0;
    uint16 private constant pPairing = 128;

    uint16 private constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[2] calldata _pubSignals) public view returns (bool) {
        assembly {
            function checkField(v) {
                if iszero(lt(v, r)) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }
            
            // G1 function to multiply a G1 value(x,y) to value in an address
            function g1_mulAccC(pR, x, y, s) {
                let success
                let mIn := mload(0x40)
                mstore(mIn, x)
                mstore(add(mIn, 32), y)
                mstore(add(mIn, 64), s)

                success := staticcall(sub(gas(), 2000), 7, mIn, 96, mIn, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }

                mstore(add(mIn, 64), mload(pR))
                mstore(add(mIn, 96), mload(add(pR, 32)))

                success := staticcall(sub(gas(), 2000), 6, mIn, 128, pR, 64)

                if iszero(success) {
                    mstore(0, 0)
                    return(0, 0x20)
                }
            }

            function checkPairing(pA, pB, pC, pubSignals, pMem) -> isOk {
                let _pPairing := add(pMem, pPairing)
                let _pVk := add(pMem, pVk)

                mstore(_pVk, IC0x)
                mstore(add(_pVk, 32), IC0y)

                // Compute the linear combination vk_x
                
                g1_mulAccC(_pVk, IC1x, IC1y, calldataload(add(pubSignals, 0)))
                
                g1_mulAccC(_pVk, IC2x, IC2y, calldataload(add(pubSignals, 32)))
                

                // -A
                mstore(_pPairing, calldataload(pA))
                mstore(add(_pPairing, 32), mod(sub(q, calldataload(add(pA, 32))), q))

                // B
                mstore(add(_pPairing, 64), calldataload(pB))
                mstore(add(_pPairing, 96), calldataload(add(pB, 32)))
                mstore(add(_pPairing, 128), calldataload(add(pB, 64)))
                mstore(add(_pPairing, 160), calldataload(add(pB, 96)))

                // alpha1
                mstore(add(_pPairing, 192), alphax)
                mstore(add(_pPairing, 224), alphay)

                // beta2
                mstore(add(_pPairing, 256), betax1)
                mstore(add(_pPairing, 288), betax2)
                mstore(add(_pPairing, 320), betay1)
                mstore(add(_pPairing, 352), betay2)

                // vk_x
                mstore(add(_pPairing, 384), mload(add(pMem, pVk)))
                mstore(add(_pPairing, 416), mload(add(pMem, add(pVk, 32))))


                // gamma2
                mstore(add(_pPairing, 448), gammax1)
                mstore(add(_pPairing, 480), gammax2)
                mstore(add(_pPairing, 512), gammay1)
                mstore(add(_pPairing, 544), gammay2)

                // C
                mstore(add(_pPairing, 576), calldataload(pC))
                mstore(add(_pPairing, 608), calldataload(add(pC, 32)))

                // delta2
                mstore(add(_pPairing, 640), deltax1)
                mstore(add(_pPairing, 672), deltax2)
                mstore(add(_pPairing, 704), deltay1)
                mstore(add(_pPairing, 736), deltay2)


                let success := staticcall(sub(gas(), 2000), 8, _pPairing, 768, _pPairing, 0x20)

                isOk := and(success, mload(_pPairing))
            }

            let pMem := mload(0x40)
            mstore(0x40, add(pMem, pLastMem))

            // Validate that all evaluations ∈ F
            
            checkField(calldataload(add(_pubSignals, 0)))
            
            checkField(calldataload(add(_pubSignals, 32)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
