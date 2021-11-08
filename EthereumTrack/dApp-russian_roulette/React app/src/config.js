export const ADDRESS = "0x7C0748f687Ff12E0baB16Fb218C090aA7fe857eE"
export const ABI = [
	{
		"inputs": [],
		"stateMutability": "nonpayable",
		"type": "constructor"
	},
	{
		"anonymous": false,
		"inputs": [
			{
				"indexed": false,
				"internalType": "address",
				"name": "loser",
				"type": "address"
			}
		],
		"name": "GameOver",
		"type": "event"
	},
	{
		"inputs": [],
		"name": "getTurn",
		"outputs": [
			{
				"internalType": "address",
				"name": "",
				"type": "address"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "isFinished",
		"outputs": [
			{
				"internalType": "bool",
				"name": "",
				"type": "bool"
			}
		],
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "register",
		"outputs": [],
		"stateMutability": "payable",
		"type": "function"
	},
	{
		"inputs": [],
		"name": "shoot",
		"outputs": [],
		"stateMutability": "nonpayable",
		"type": "function"
	}
]