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
    uint256 private constant alphax  = 2229544785081736568127879340931216801578177112243523721536175607567987144353;
    uint256 private constant alphay  = 1088539665919658472352678692054798381469257871882825099216877971432927845783;
    uint256 private constant betax1  = 111390626814946310569311654293849551471551487868780418719370006249819124551;
    uint256 private constant betax2  = 1906607822026759866867347934501224870365858324317583305954339470234863206135;
    uint256 private constant betay1  = 10878998343454755032053799641266231527945388029337000775868327447381184701077;
    uint256 private constant betay2  = 1005279208617395647361698165979959285082847135234720578527887751585321404645;
    uint256 private constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 private constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 private constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 private constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 private constant deltax1 = 10848925849209510114756798114912105561922224431993626621771151734609374440786;
    uint256 private constant deltax2 = 10311527668907593841862147184806951309670710091349493310746676613099313836964;
    uint256 private constant deltay1 = 19825927015073818825807925169082959508222344406778506043558321615661177879989;
    uint256 private constant deltay2 = 20692148541132425141425856675384944710931375936477625350257214793659983573531;

    
    uint256 private constant IC0x = 18260549661018729967659961166147765190683601882451195907068074121747153171562;
    uint256 private constant IC0y = 14119167973962640750682527426730191048070975670417924433347093784944205137098;
    
    uint256 private constant IC1x = 72235531075710947928324348074378253012909209778625378570170466568386386832;
    uint256 private constant IC1y = 6216052265392032618438943816705003084306432818776881939164423041532497096884;
    
    uint256 private constant IC2x = 20944105576876682231539804291770433752260264028567103780428412550401690211118;
    uint256 private constant IC2y = 21323298517520907823948575970929902472134025772418641119139222245134208489187;
    
 
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
