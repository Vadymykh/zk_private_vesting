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

contract VestingWithdrawVerifier {
    // Scalar field size
    uint256 private constant r    = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    // Base field size
    uint256 private constant q   = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Verification Key data
    uint256 private constant alphax  = 5001555807923958609831249562334282563999281432127581558144645925785011133620;
    uint256 private constant alphay  = 7945925998697378963880376753225993393580726393676929697278332096433071949058;
    uint256 private constant betax1  = 19487816771187409843942788176449720867494274725721392792206222524729142106522;
    uint256 private constant betax2  = 20268775466211285660146117240775206437819825895912225947650904121430942121158;
    uint256 private constant betay1  = 19522727802465623968030060882926185363849844949871271238238398352305508681237;
    uint256 private constant betay2  = 11125367539254638860380306210596585732745054175647531067496298255679408956251;
    uint256 private constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 private constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 private constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 private constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 private constant deltax1 = 18062371554006870730289879256222920042630834447631378331884280639991311115639;
    uint256 private constant deltax2 = 4864742744158083345861231640805995452689054824492845631732772489421229833087;
    uint256 private constant deltay1 = 12520743615461053254102340896335234903245472005494569948104747094113197774078;
    uint256 private constant deltay2 = 5815856862597921969091025926849981027864162247810551974719054685158884299054;

    
    uint256 private constant IC0x = 3868557789617161738868122061423773315869180527108934798086265857274461717949;
    uint256 private constant IC0y = 9922140178242102727313371606793892832018045043167215521461814509162788217416;
    
    uint256 private constant IC1x = 11980896460706040712238911772802405741216622343334244785197467145780110469464;
    uint256 private constant IC1y = 19626334911716426817608101321494835180545990420866880515577046189273192833290;
    
    uint256 private constant IC2x = 11111690677719517822904655481631717029927176274217285839353727535323625936809;
    uint256 private constant IC2y = 19066680533549648729472261630592410835511671009290270247914124153879998343638;
    
    uint256 private constant IC3x = 19258518878800433445549604588188047769816201714070298243362114872310475143392;
    uint256 private constant IC3y = 18294887816820984629367451759044706426825290968154758056683203987165676252907;
    
    uint256 private constant IC4x = 6339224037891122526187984324311989109993341781611520212830530054747140296923;
    uint256 private constant IC4y = 20291966453783925939699066216588419366178973532205324621377111327720633222244;
    
    uint256 private constant IC5x = 21752991067448386407332060178325958996824149022528836864074973195544221316994;
    uint256 private constant IC5y = 7907012265065982362266394960677222659010765257606126095477237852976770271571;
    
 
    // Memory data
    uint16 private constant pVk = 0;
    uint16 private constant pPairing = 128;

    uint16 private constant pLastMem = 896;

    function verifyProof(uint[2] calldata _pA, uint[2][2] calldata _pB, uint[2] calldata _pC, uint[5] calldata _pubSignals) public view returns (bool) {
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
                
                g1_mulAccC(_pVk, IC3x, IC3y, calldataload(add(pubSignals, 64)))
                
                g1_mulAccC(_pVk, IC4x, IC4y, calldataload(add(pubSignals, 96)))
                
                g1_mulAccC(_pVk, IC5x, IC5y, calldataload(add(pubSignals, 128)))
                

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
            
            checkField(calldataload(add(_pubSignals, 64)))
            
            checkField(calldataload(add(_pubSignals, 96)))
            
            checkField(calldataload(add(_pubSignals, 128)))
            

            // Validate all evaluations
            let isValid := checkPairing(_pA, _pB, _pC, _pubSignals, pMem)

            mstore(0, isValid)
             return(0, 0x20)
         }
     }
 }
