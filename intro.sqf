sleep 3;
5 fadeSound 1;
playMusic "intro";
titleCut ["< 欢迎来到山猫战术研究讨论组 >", "BLACK IN", 10];

sleep 14.2;
titleText ["< 记住！你不是一个人在战斗！ > \n\n", "PLAIN"];
sleep 5;
titleFadeOut 3;

sleep 6.3;
titleText ["< SMAO山猫 管理员 > *二级中士_撒野*二级下士_豹斯*一级下士_六月*", "PLAIN"];
sleep 6;
titleFadeOut 4;

	// Info text
	[str ("Spiel Modus Eroberung!"), str("Viel Spaß Team!"), str(date select 1) + "." + str(date select 2) + "." + str(date select 0)] spawn BIS_fnc_infoText;

	sleep 3;
	"dynamicBlur" ppEffectEnable true;   
	"dynamicBlur" ppEffectAdjust [6];   
	"dynamicBlur" ppEffectCommit 0;     
	"dynamicBlur" ppEffectAdjust [0.0];  
	"dynamicBlur" ppEffectCommit 5;  

	titleCut ["< 我们的团队 BOBcatsSMAO山猫战术研究讨论组 Ts3: vip1.ts1.cn:6525 QQ群：423313572  非常希望你的加入 >", "BLACK IN", 30];
	

