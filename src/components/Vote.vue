<template>
    <div class="common-layout">
        <el-container v-if="!loginState">
            <el-header height="200">
                <div class="vote-info">
                    <img :src="pic" width="750" aspect-ratio="auto">
                </div>
                <div class="status">
                    <span v-if="lock">投票已結束</span>
                    <span v-else>投票進行中</span>
                </div>
            </el-header>
            <el-main>
                <div class="user-info">
                    <br />
                    <label><b>ID</b></label>
                    <input type="string" placeholder='請輸入身分證號碼' v-model.trim="ID" @keyup="checkNewUser(ID)" />
                    <br />
                    <label v-if="!newUser"><b>帳號</b></label>
                    <input v-if="!newUser" type="string" placeholder='請輸入帳號' v-model.trim="curAccount" />
                    <br v-if="!newUser" />
                    <br />

                    <button type="button" v-if="newUser" @click="register">註冊</button>
                    <button type="button" v-else @click="login">登入</button>
                    <br />
                    <el-alert v-if="fail != null" title="Error" type="error" center :closable="false" show-icon>{{ fail
                        }}
                    </el-alert>
                    <br v-else />
                </div>
            </el-main>
        </el-container>
        <el-container v-else>
            <el-header height="80">
                <div class="title">
                    <h1>Voting</h1>
                </div>

                <div class="status">
                    <div v-if="lock">投票已結束</div>
                    <div v-else>投票進行中</div>
                    <br />
                </div>
            </el-header>
            <el-container>
                <el-aside width="35%">
                    <div v-if="loginState" class="user-login-info">
                        <span v-if="!voter.voted" class='highlight'>尚未投票 </span>
                        <span v-else>已完成投票 </span>
                        <br>ID:{{ ID }}<br>帳號：{{ curAccount }}
                        <br />
                        <button type="button" @click="logout">登出</button>
                        <br />
                        <br />
                    </div>
                    <div class="user-login-info" v-if="isAuthor && loginState">
                        <div>
                            <h2>管理員設定</h2>
                            <button type="button" :disabled="!lock" @click="openVote">開啟投票</button>
                            <button type="button" :disabled="lock" @click="closeVote">關閉投票</button>
                        </div>
                    </div>
                </el-aside>
                <el-main>
                    <div v-if="loginState" class="vote-info">
                        <p align=center>
                        <table border="1" style="width:80%">
                            <thead>
                                <tr>
                                    <th v-for="i in 3" :key="i">
                                        <span>候選{{ i }}</span>
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr>
                                    <td v-for="proposal in proposals" :key="proposal" align='center' valign="middle">
                                        <span>{{ proposal.name }}</span>
                                    </td>
                                </tr>
                                <tr>
                                    <td v-for="proposal in proposals" :key="proposal" align='center' valign="middle">
                                        <img :src="proposal.pic" width='200' aspect-ratio auto>
                                    </td>
                                </tr>
                                <tr>
                                    <td v-for="proposal in proposals" :key="proposal" align='center' valign="middle">
                                        <span>政見：{{ proposal.description }}</span>
                                    </td>
                                </tr>
                                <tr>
                                    <td v-for="proposal in proposals" :key="proposal" align='center' valign="middle">
                                        <span>email:{{ proposal.email }}</span>
                                    </td>
                                </tr>
                            </tbody>
                            <tfoot>
                                <tr>
                                    <td v-for="(proposal, key) in proposals" :key="proposal" align='center'
                                        valign="middle">
                                        <span v-if="lock"> 共獲得：{{ proposal.voteCnt }}票 </span>
                                        <el-button v-else type="success" round :icon="Check" :disabled="voter.voted"
                                            @click="vote(key)">投{{ key + 1 }}號
                                        </el-button>
                                    </td>
                                </tr>
                            </tfoot>
                        </table>
                        </p>
                    </div>
                </el-main>
            </el-container>
        </el-container>
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
            pic: "https://image.shutterstock.com/image-illustration/evoting-concept-web-banner-flat-260nw-649887880.jpg",
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

    // 網頁生成時
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

            if (this.ID == null) {
                this.fail = "ID不能為空"
                return
            }
            if (this.ID.length != 10) {
                this.fail = "ID格式錯誤"
                return
            }

            await this.voting.voterCnt().then(
                r => {
                    if (r < 10) {
                        this.web3.eth.getAccounts().then(accs => {
                            this.voting.register(this.ID, accs[r], { from: this.account }).then(
                                () => {
                                    this.loginState = true
                                    this.account = this.curAccount = accs[r]
                                    alert("註冊成功，請記住你的帳號")
                                }
                            ).then(() => this.renewInfo())
                        })
                    } else {
                        this.fail = "已達帳號上限"
                        return;
                    }
                })
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
            this.newUser = true
            await this.renewInfo()
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
    border: 1px solid rgb(27, 139, 154);
    border-radius: 4px;
    padding: 5px;
}

.status {
    width: 70%;
    margin: auto;
    padding: 10px;
    border-radius: 5px;
    background-color: #f2f2f2;
    color: #333;
}

.user-info {
    margin: auto;
    width: 50%;
    border: 5px dotted rgb(59, 126, 90);
    border-radius: 10px;
}

.user-login-info {
    margin: auto;
    border: 5px dotted rgb(59, 126, 90);
    border-radius: 10px;
}

.fail {
    font-size: 20px;
    color: red;
}

.highlight {
    color: red;
}

.common-layout {
    margin: auto;
}
</style>
