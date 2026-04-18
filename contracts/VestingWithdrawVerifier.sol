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
    uint256 private constant alphax  = 8894482517148508212670181452754894593506791711079622189313056659494524307843;
    uint256 private constant alphay  = 14735284581865097408712138426645047816392903319244654407367444074606738636409;
    uint256 private constant betax1  = 16978850477188900749015834639447579483453919996306112354887894435237034661389;
    uint256 private constant betax2  = 6119518361515195208648391999675459485840474908792424392692147761210257320447;
    uint256 private constant betay1  = 3683998147818377027497822505534804204651720640854585495621544944920314402392;
    uint256 private constant betay2  = 17610390926922852321508947694129108327852075126576709685668367689682499998165;
    uint256 private constant gammax1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 private constant gammax2 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 private constant gammay1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 private constant gammay2 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    uint256 private constant deltax1 = 10586014965694891619119238485364476414231667822427989874342508915753022743500;
    uint256 private constant deltax2 = 7664728903965250357297523928404222034272943175673177405593959629435826948999;
    uint256 private constant deltay1 = 3067087125138011750480285691368708291842172643826028247417034667787297500458;
    uint256 private constant deltay2 = 11445745470845983284102481611935515478247635372093656941768267036880790294877;

    
    uint256 private constant IC0x = 12838473766769140968717491521427501236594645412359701559074580792491147113664;
    uint256 private constant IC0y = 308734886493652788344524842988942158919602199120972128107742643614619275495;
    
    uint256 private constant IC1x = 16305539057608609557764675635443740163538071615121943383813244184088301632630;
    uint256 private constant IC1y = 1920269114924271727258269507279997598457388246893394329528676580669152693769;
    
    uint256 private constant IC2x = 18603563243293505472956020063067021896511520859243828845867734642177285457610;
    uint256 private constant IC2y = 12623883379434235071025794674930321295360803683451716136838513690100409013331;
    
    uint256 private constant IC3x = 13152891031923319987508891208195337449594069988750506372571557950156176213698;
    uint256 private constant IC3y = 21477243742600778844979797674832787953608391856432467535246543154280686967974;
    
    uint256 private constant IC4x = 12200250955303412583674624963889387603194370784862117772165062771918881745302;
    uint256 private constant IC4y = 13142366109939241723658358418700221394096590524886121037579509852556451433427;
    
    uint256 private constant IC5x = 4203530582847261746229153318118549216880727257536720534721414694907853960033;
    uint256 private constant IC5y = 1733897370217468186305743004180966046902631232806391922896321624156044064451;
    
 
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
