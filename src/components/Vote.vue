<template>
    <div class="content">
        <div class="title">
            <h1>Voting</h1>
        </div>
        <!-- <div class="vote">
            <div v-for="candidate in candidates" :key="candidate">
                <div class="candidate">
                    <div class="candidate-name">
                        <h2>{{ candidate.name }}</h2>
                    </div>
                    <div class="candidate-vote">
                        <button @click="vote(index)">Vote</button>
                    </div>
                </div>
            </div>
        </div> -->

        <div class="status">
            <div v-if="!lock">開放投票</div>
            <div v-if="lock">投票已結束</div>
            <!-- <div> {{ proposals }} </div> -->
        </div>

        <div v-if="!lock" class="card-bkg">
            <input v-model="message" />

            <button @click="setAccount">設定帳號</button>
        </div>

        <div class="manager" v-if="isAuthor">
            <div class="manager-title">
                <h2>管理員設定</h2>
                <button :disabled="!lock" @click="openVote">開啟投票</button>
                <button :disabled="lock" @click="closeVote">關閉投票</button>
            </div>
        </div>
    </div>
</template>

<script>
import Web3 from "web3";
import contract from "@truffle/contract";
import Vote from '../../build/contracts/Vote.json';

export default {
    name: 'My_vote',
    data() {
        return {
            voted: null,
            lock: null,
            isAuthor: null,
            message: null,
            proposals: {
                name: null,
                votecount: null,
            },
        };
    },

    async created() {
        await this.initWeb3Account()
        await this.initContract()
        await this.getCrowdInfo()
    },

    methods: {
        async initWeb3Account() {
            this.provider = new Web3.providers.HttpProvider("http://127.0.0.1:8545");
            this.web3 = new Web3(this.provider);
            this.web3.eth.getAccounts().then(accs => {
                this.account = accs[0]
            });
            alert("connect to blockchain");
        },

        // 初始化合约实例
        async initContract() {
            const voteContract = contract(Vote);
            voteContract.setProvider(this.provider);
            this.voting = await voteContract.deployed()
        },

        // 获取合约的状态信息
        async getCrowdInfo() {
            // this.voting.voter(this.account).then(
            //   r => {
            //     this.voted = r.voted
            //   }
            // );
            this.voting.proposals().then(
                r => this.proposals = r
            );
            this.voting.lock().then(
                r => this.lock = r
            );
            this.voting.chairperson().then(
                r => this.isAuthor = this.account == r
            );
        },

        async setAccount() {
            this.account = this.message
            await this.getCrowdInfo()
        },

        closeVote() {
            this.voting.setLock(true, { from: this.account }).then(() =>
                this.getCrowdInfo()
            );
        },

        openVote() {
            this.voting.setLock(false, { from: this.account }).then(() =>
                this.getCrowdInfo()
            );
        },

        vote: function (x) {
            this.voting.vote({ from: this.account, value: x }).then(() =>
                this.getCrowdInfo()
            );
        },

        // 赎回
        withdraw() {
            // this.voting.withdraw(
            //   this.voting.withdraw({
            //     from: this.account
            //   }).then(() => {
            //     this.getCrowdInfo()
            //   })
            // );
        },

        // 提取资金
        withdrawFund() {
            // this.voting.withdrawFund({
            //   from: this.account
            // }).then(() => {
            //   this.getCrowdInfo()
            // })
        },

    }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h3 {
    margin: 40px 0 0;
}

ul {
    list-style-type: none;
    padding: 0;
}

li {
    display: inline-block;
    margin: 0 10px;
}

a {
    color: #42b983;
}
</style>
