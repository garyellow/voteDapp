<template>
    <div class="content">
        <div class="title">
            <h1>Voting</h1>
        </div>

        <div class="status">
            <div v-if="!lock">投票進行中</div>
            <div v-if="lock">投票已結束</div>
        </div>

        <div v-if="!loginState" class="user-info">
            <label>ID</label>
            <input v-model.trim="ID" />
            <br />
            <label>帳號</label>
            <input v-model.trim="curAccount" />
            <br />
            <button @click="getNewAccount">新帳號</button>
            <button @click="register">註冊</button>
            <button @click="login">登入</button>
            <div v-if="fail != null">{{ fail }}</div>
        </div>

        <div v-if="loginState" class="user-info">
            <div>ID：{{ ID }}</div>
            <div>帳號：{{ curAccount }}</div>
            <br />
            <button @click="logout">登出</button>
            <br />
            <div>{{ proposals }}</div>
            <!-- <div>{{ proposals[0] }}</div> -->
            <!-- <div>{{ proposals[0].name }}</div> -->
            <!-- <li v-for="i in proposals">{{ i }}</li> -->
            <br />
            <button @click="vote(0)">投1號</button>
            <button @click="vote(1)">投2號</button>
            <button @click="vote(2)">投3號</button>
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
            lock: null,
            isAuthor: null,
            proposals: [],
            curAccount: null,
            ID: null,
            loginState: false,
            fail: null,
        };
    },

    async created() {
        await this.initWeb3Account()
        await this.initContract()
        await this.renewInfo()
    },

    methods: {
        async initWeb3Account() {
            this.provider = new Web3.providers.HttpProvider("http://127.0.0.1:8545");
            this.web3 = new Web3(this.provider);
            this.web3.eth.getAccounts().then(accs => this.account = accs[0]);
        },

        async initContract() {
            const voteContract = contract(Vote)
            voteContract.setProvider(this.provider)
            this.voting = await voteContract.deployed()
            this.voting.proposalCnt().then(cnt => {
                for (let index = 0; index < cnt; index++) {
                    this.voting.proposals(index).then(res => {
                        this.proposals.push({ name: res.name, voteCnt: res.voteCnt, win: res.win })
                    })
                }
            })
        },

        async renewInfo() {
            this.voting.proposalCnt().then(cnt => {
                for (let index = 0; index < cnt; index++) {
                    this.voting.proposals(index).then(res => {
                        this.proposals[index] = { name: res.name, voteCnt: res.voteCnt, win: res.win }
                    })
                }
            })
            this.voting.lock().then(
                r => this.lock = r
            );
            this.voting.chairperson().then(
                r => this.isAuthor = this.account == r
            );
        },

        login() {
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
            ).then(() => this.renewInfo())
        },

        async logout() {
            this.loginState = false
            this.web3.eth.getAccounts().then(accs => this.account = accs[0])
            this.curAccount = null
            this.ID = null
            await this.renewInfo()
        },

        getNewAccount() {
            this.voting.voterCnt().then(
                r => {
                    if (r < 10) {
                        this.web3.eth.getAccounts().then(accs => this.curAccount = accs[r])
                    } else {
                        this.fail = "已達帳號上限"
                    }
                }).then(() => this.renewInfo())
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

            await this.voting.register(this.ID, this.curAccount, { from: this.account }).then(
                () => {
                    this.loginState = true
                    this.account = this.curAccount
                    alert("註冊成功，請記住你的帳號")
                }
            ).then(() => this.renewInfo())

            if (this.fail == null) {
                this.fail = "註冊失敗"
            }
        },

        closeVote() {
            this.voting.setLock(true, { from: this.account }).then(() => this.renewInfo())
        },

        openVote() {
            this.voting.setLock(false, { from: this.account }).then(() => this.renewInfo())
        },

        vote: function (x) {
            this.voting.vote(x, { from: this.account }).then(() => this.renewInfo())
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
