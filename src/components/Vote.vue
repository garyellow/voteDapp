<template>
    <div class="content" @mouseenter="renewInfo">
        <div class="title">
            <h1>Voting</h1>
        </div>

        <div class="status">
            <div v-if="lock">投票已結束</div>
            <div v-else>投票進行中</div>
        </div>

        <div v-if="!loginState" class="user-info">
            <br />
            <label>ID</label>
            <input v-model.trim="ID" @keyup="checkNewUser(ID)" />
            <br />
            <label>帳號</label>
            <input v-model.trim="curAccount" />
            <br />
            <br />
            <button type="button" @click="getNewAccount">新帳號</button>
            <button type="button" v-if="newUser" @click="register">註冊</button>
            <button type="button" v-else @click="login">登入</button>
            <div v-if="fail != null">{{ fail }}</div>
            <br v-else />
            <br />
        </div>

        <div v-if="loginState" class="user-info">
            <br />
            <label class="long-label">ID：{{ ID }}</label>
            <br />
            <label class="long-label">帳號：{{ curAccount }}</label>
            <br />
            <button type="button" @click="logout">登出</button>
            <br />
            <br />
        </div>
        <div v-if="loginState" class="vote-info">
            <br />
            <li v-for="(proposal, key) in proposals" :key="proposal">
                <span>{{ key + 1 }}. {{ proposal.name }}</span>
                <span v-if="lock"> 共獲得：{{ proposal.voteCnt }}票</span>
                <button type="button" v-else :disabled="voter.voted" @click="vote(key)">投{{ key + 1 }}號</button>
                <span v-if="proposal.win"> 最高票!!!</span>
            </li>
            <br />
            <br />
            <div v-if="voter.voted">你已經投過票了，投的是{{ parseInt(voter.voteto, base) + 1 }}號</div>
            <div v-else>你還沒投票</div>
        </div>

        <div class="manager" v-if="isAuthor && loginState">
            <div class="manager-title">
                <h2>管理員設定</h2>
                <button type="button" :disabled="!lock" @click="openVote">開啟投票</button>
                <button type="button" :disabled="lock" @click="closeVote">關閉投票</button>
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
            proposalCnt: 0,
            voter: null,
            ID: null,
            curAccount: null,
            newUser: true,
            loginState: null,
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
            await this.web3.eth.getAccounts().then(accs => this.account = accs[0]);
        },

        async initContract() {
            const voteContract = contract(Vote)
            voteContract.setProvider(this.provider)
            this.voting = await voteContract.deployed()
            await this.voting.proposalCnt().then(cnt => {
                for (let index = 0; index < cnt; index++) {
                    this.voting.proposals(index).then(res => {
                        this.proposals.push(res)
                    })
                }
            })

            this.loginState = false
        },

        async renewInfo() {
            this.voting.proposalCnt().then(r => this.proposalCnt = r.toNumber())

            for (let index = 0; index < this.proposalCnt; index++) {
                await this.voting.proposals(index).then(res => {
                    this.proposals[index] = res
                })
            }

            this.voting.voters(this.account).then(voter => {
                this.voter = voter
            })

            this.voting.lock().then(
                r => this.lock = r
            );
            this.voting.chairperson().then(
                r => this.isAuthor = this.account == r
            );
        },

        checkNewUser() {
            this.voting.newUser(this.ID, { from: this.account }).then(
                r => this.newUser = r
            );
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
            this.web3.eth.getBalance(this.curAccount).then(balance => {
                if (balance.toNumber() == 0) {
                    this.fail = "帳號錯誤"
                    return
                }
            })

            await this.voting.register(this.ID, this.curAccount, { from: this.account }).then(
                () => {
                    this.loginState = true
                    this.account = this.curAccount
                    alert("註冊成功，請記住你的帳號")
                }
            ).then(() => this.renewInfo())

            if (this.loginState == false) {
                this.fail = "註冊失敗，請檢察ID或帳號是否已被註冊"
            }
        },

        async login() {
            this.fail = null
            if (this.curAccount == null || this.ID == null) {
                this.fail = "帳號和ID不能為空"
                return
            }
            if (this.curAccount.length != 42 || this.ID.length != 10) {
                this.fail = "帳號或ID格式錯誤"
                return
            }
            this.web3.eth.getBalance(this.curAccount).then(balance => {
                if (balance.toNumber() == 0) {
                    this.fail = "帳號錯誤"
                    return
                }
            })

            await this.voting.checkAccount(this.ID, this.curAccount, { from: this.account }).then(
                r => {
                    if (r == 1) {
                        this.loginState = true
                        this.account = this.curAccount
                        alert("登入成功")
                    } else if (r == 2) {
                        this.fail = "ID不存在，請先註冊"
                    } else if (r == 3) {
                        this.curAccount = null
                        this.fail = "帳號錯誤，請重新輸入"
                    } else if (r == 4) {
                        this.curAccount = null
                        this.fail = "帳號錯誤，請重新輸入"
                    }
                }
            ).then(() => this.renewInfo())
        },

        async logout() {
            this.fail = null
            this.loginState = false
            this.web3.eth.getAccounts().then(accs => this.account = accs[0])
            this.curAccount = null
            this.ID = null
            await this.renewInfo()
        },

        getNewAccount() {
            this.fail = null
            this.voting.voterCnt().then(
                r => {
                    if (r < 10) {
                        this.web3.eth.getAccounts().then(accs => this.curAccount = accs[r])
                    } else {
                        this.fail = "已達帳號上限"
                    }
                }).then(() => this.renewInfo())
        },


        closeVote() {
            this.voting.setLock(true, { from: this.account }).then(() => this.renewInfo())
        },

        openVote() {
            this.voting.setLock(false, { from: this.account }).then(() => this.renewInfo())
        },

        vote(x) {
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
    width: 70%;
    height: 25px;
    border: 1px solid rgb(160, 160, 255);
    border-radius: 5px;
    font-size: 14px;
}

.user-info {
    margin: auto;
    width: 40%;
    border: 5px dotted rgb(116, 255, 183);
}

.long-label {
    float: left;
    width: 100%;
}
</style>
