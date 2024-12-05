// SPDX-License-Identifier: MIT
// 这行声明了使用 MIT 开源许可证，表示该合约的代码可以自由使用、复制、修改和分发。

pragma solidity ^0.8.19;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
// Governor 合约是 OpenZeppelin 提供的标准治理合约，包含了 DAO 治理所需的基本功能，如提案、投票等。

import {GovernorSettings} from "@openzeppelin/contracts/governance/extensions/GovernorSettings.sol";
// GovernorSettings 扩展模块用于设置治理合约的一些基本配置，如投票延迟时间、投票周期、提案门槛等。

import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
// GovernorCountingSimple 扩展模块实现了简单的投票计数逻辑，适用于不复杂的投票机制，如支持多数制投票。

import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
// GovernorVotes 扩展模块通过一个 token 实现投票权的分配。每个投票者的投票权与他们持有的 token 数量相关。

import {GovernorVotesQuorumFraction} from
    "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
// GovernorVotesQuorumFraction 扩展模块用于设置提案通过所需的最小选民比例（即 quorum）。这个比例是投票总数的一个分数。

import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
// GovernorTimelockControl 扩展模块用于在提案通过后，要求一定的时间锁（Timelock）才能执行提案，增加安全性，避免快速执行恶意提案。

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
// TimelockController 提供了一个时间锁合约的功能，用于延迟执行某些操作，确保在特定时间后才能执行提案的内容。

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
// IVotes 是一个接口，允许合约访问投票权的相关功能，通常由 token 合约实现，用来控制投票权的分配。

import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
// IGovernor 是一个接口，定义了治理合约的基本功能，如提案、投票、查询提案状态等。

// 自定义治理合约 MyGovernor，继承自多个 OpenZeppelin 提供的治理模块
contract MyGovernor is
    Governor, // 基本治理功能，如提案、投票等
    GovernorSettings, // 设置治理参数，如投票延迟、投票周期、提案门槛
    GovernorCountingSimple, // 简单的投票计数方法
    GovernorVotes, // 基于 token 的投票权分配
    GovernorVotesQuorumFraction, // 设置提案通过所需的最小选民比例
    GovernorTimelockControl // 设置时间锁，延迟执行提案
{
    // 两个合约地址. 由 token 合约实现的投票权接口, 以及时间锁控制器
    constructor(IVotes _token, TimelockController _timelock)
        Governor("MyGovernor") // 设置治理合约的名称
        GovernorSettings(1, /* 1 block */ 50400, /* 1 week */ 0) // 投票延迟时间为1区块，投票周期为1周，提案门槛为0...一个区块时间是12秒, 此外/**/就是作为一个注释
        GovernorVotes(_token) // 使用提供的 token 合约作为投票权分配基础
        GovernorVotesQuorumFraction(4) // 设置 quorum 为投票总数的4%
        GovernorTimelockControl(_timelock) // 使用提供的时间锁控制器
    {}

    // 以下是重写函数，满足 Solidity 语言的继承要求，并调用父类的对应方法。

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay(); // 返回投票延迟时间
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod(); // 返回投票周期
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber); // 返回特定区块号的 quorum，表示提案通过所需的最小投票数
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId); // 返回提案的当前状态
    }

    function propose(
        address[] memory targets, // 提案的目标合约地址, 提议的函数将在目标合约上调用
        uint256[] memory values, // 要给目标合约发送的以太币数量
        bytes[] memory calldatas, // 交易, 以及要传给提案函数的参数
        string memory description // 提案的描述
    ) public override(Governor, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description); // 创建提案, 对参数进行 hash, 返回提案 ID
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold(); // 返回创建提案所需的门槛
    }

    // 这些参数同样进行哈希, 并验证提案, 然后执行提案
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash); // 执行提案
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash); // 取消提案
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor(); // 返回执行提案的合约地址
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId); // 检查合约是否支持特定的接口
    }
}
