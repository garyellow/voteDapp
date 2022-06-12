<template>
    <div class="content">
        <div class="title">
            <h1>Voting</h1>
        </div>
        <div>{{ account }}</div>

        <div class="status">
            <div v-if="!lock">投票進行中</div>
            <div v-if="lock">投票已結束</div>
            <div>{{ loginState }}</div>
        </div>

        <div v-if="!loginState" class="user-info">
            <label>帳號</label>
            <input v-model.trim="curAccount" />
            <br />
            <!-- <button @click="setAccount">設定帳號</button> -->
            <label>ID</label>
            <input v-model.trim="ID" />
            <br />
            <button @click="getNewAccount">新帳號</button>
            <button @click="register">註冊</button>
            <button @click="login">登入</button>
            <div v-if="fail != null">{{ fail }}</div>
        </div>

        <div v-if="loginState" class="user-info">
            <label>帳號</label>
            <input :disable="true" v-model.trim="curAccount" />
            <br />
            <label>ID</label>
            <input :disable="true" v-model.trim="ID" />
            <br />
            <button @click="logout">登出</button>
        </div>

        <div class="manager" v-if="isAuthor && loginState">
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
            proposals: {
                name: null,
                votecount: null,
            },
            curAccount: null,
            ID: null,
            loginState: false,
            fail: null,
            temp: null,
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
            this.web3.eth.getAccounts().then(accs => this.account = accs[0]);
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
            this.voting.proposals({ from: this.account }).then(
                r => this.proposals = r
            );
            this.voting.lock({ from: this.account }).then(
                r => this.lock = r
            );
            this.voting.chairperson({ from: this.account }).then(
                r => this.isAuthor = this.account == r
            );
        },

        async login() {
            if (this.curAccount == null || this.ID == null) {
                this.fail = "帳號和ID不能為空"
                return
            }
            if (this.curAccount.length != 42 || this.ID.length != 10) {
                this.fail = "帳號或ID格式錯誤"
                return
            }
            if (this.web3.eth.getBalance(this.curAccount) == 0) {
                this.fail = "帳號錯誤"
                return
            }
            this.voting.checkAccount(this.ID, this.curAccount, { from: this.account }).then(
                r => {
                    alert(r)
                    if (r == 1) {
                        this.loginState = true
                        this.account = this.curAccount
                        this.fail = null
                    } else if (r == 2) {
                        this.fail = "ID不存在，請先註冊"
                    } else if (r == 3) {
                        this.fail = "帳號不存在，請先註冊"
                    } else if (r == 4) {
                        this.ID = this.curAccount = null
                        this.fail = "ID 或 帳號錯誤，請重新輸入"
                    }
                }
            ).then(() => this.getCrowdInfo())
        },

        async logout() {
            this.loginState = false
            this.web3.eth.getAccounts().then(accs => this.account = accs[0])
            this.curAccount = null
            this.ID = null
            this.getCrowdInfo()
        },

        getNewAccount() {
            this.voting.getVoterCnt({ from: this.account }).then(
                r => {
                    if (r < 10) {
                        this.web3.eth.getAccounts().then(accs => this.curAccount = accs[r])
                    } else {
                        this.fail = "已達帳號上限"
                    }
                }).then(() => this.getCrowdInfo())
        },

        async register() {
            this.fail = null
            if (this.curAccount == null || this.ID == null) {
                this.fail = "帳號和ID不能為空"
                return
            }
            if (this.curAccount.length != 42 || this.ID.length != 10) {
                this.fail = "帳號或ID格式錯誤"
                return
            }
            if (this.web3.eth.getBalance(this.curAccount) == 0) {
                this.fail = "帳號錯誤"
                return
            }
            this.voting.register(this.ID, this.curAccount, { from: this.account }).then(
                () => {
                    this.loginState = true
                    this.account = this.curAccount
                    this.fail = "註冊成功"
                }
            ).then(() => this.getCrowdInfo())

        },

        async closeVote() {
            this.voting.setLock(true, { from: this.account }).then(() => this.getCrowdInfo())
        },

        async openVote() {
            this.voting.setLock(false, { from: this.account }).then(() => this.getCrowdInfo())
        },

        vote: function (x) {
            this.voting.vote({ from: this.account, value: x }).then(() => this.getCrowdInfo())
        },
    }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
label {
    display: inline-block;
    width: 40px;
}

input {
    width: 30%;
    height: 25px;
    border: 1px solid rgb(160, 160, 255);
    border-radius: 5px;
    padding: 0 10px;
    font-size: 14px;
}
</style>
