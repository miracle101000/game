import 'dart:io';
import 'dart:math';

import 'package:animated_background/animated_background.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:wakelock/wakelock.dart';

class Body extends StatefulWidget {
  final PageController pageController;
  const Body({super.key, required this.pageController});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> with TickerProviderStateMixin {
  int count = 0;
  Color color = Colors.orangeAccent.shade700;
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  RewardedInterstitialAd? _rewardedInterstitialAd;
  int _numRewardedInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;
  int mulitplier = 1;

  @override
  void initState() {
    super.initState();
    init();
    audioPlayer.open(Audio("assets/sound/tap.wav"),
        autoStart: false, showNotification: false);
    _createRewardedInterstitialAd();
  }

  @override
  void dispose() {
    super.dispose();
    Wakelock.disable();
    _rewardedInterstitialAd?.dispose();
    audioPlayer.dispose();
  }

  init() async {
    count = await Preferences.getData("count") ?? 0;
    mulitplier = await Preferences.getData("mulitplier") ?? 1;
    setState(() {});
    Wakelock.enable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              _showRewardedInterstitialAd();
            },
            child: Container(
              width: 70,
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.deepOrange.shade900,
                  borderRadius: BorderRadius.circular(5)),
              child: AutoSizeText(
                "Watch Ad x${mulitplier + 1}",
                textAlign: TextAlign.center,
                maxLines: 2,
                style:
                    GoogleFonts.rubikBubbles(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          SizedBox(
            height: 8,
          ),
          FloatingActionButton(
            backgroundColor: Colors.deepOrange.shade900,
            onPressed: () {
              widget.pageController.animateToPage(0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut);
            },
            child: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: AnimatedBackground(
        vsync: this,
        behaviour:
            RandomParticleBehaviour(options: ParticleOptions(baseColor: color)),
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.07,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      format(count),
                      style: GoogleFonts.rubikBubbles(
                          color: Colors.white, fontSize: 30),
                    )
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: 20,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 100),
                    child: LiquidLinearProgressIndicator(
                      value: count / 10000000,
                      valueColor: AlwaysStoppedAnimation(color),
                      backgroundColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      borderWidth: 0.0,
                      borderRadius: 12.0,
                      direction: Axis.vertical,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (count < 10000000) {
                      await Future.wait([
                        Future(() {
                          count += mulitplier;
                          color = getRandomColor();
                          setState(() {});
                        }),
                        Future(() async {
                          await HapticFeedback.heavyImpact();
                        }),
                        Future(() {
                          audioPlayer.play();
                        }),
                      ]);
                      Preferences.saveData("count", count);
                      if (Platform.isIOS && count % 50 == 0) {
                        _showRewardedInterstitialAd();
                      }
                    } else {
                      Preferences.saveData("count", 0);
                      show();
                    }
                  },
                  child: Text(
                    "Tap",
                    style: GoogleFonts.rubikBubbles(
                        color: Colors.white, fontSize: 30),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color getRandomColor() {
    Random random = Random();
    int red = random.nextInt(256);
    int green = random.nextInt(256);
    int blue = random.nextInt(256);

    return Color.fromRGBO(red, green, blue, 1.0);
  }

  int generateRandomNumber() {
    Random random = Random();
    return random.nextInt(17); // Generates a random number between 0 and 16
  }

  String format(int value) {
    return NumberFormat('#,###').format(value);
  }

  show() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          return Dialog(
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    height: 50,
                  ),
                  Text(
                    "Congratulations",
                    style: GoogleFonts.rubikBubbles(
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.pageController.animateToPage(0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut);
                      },
                      child: Text(
                        "Go back",
                        style: GoogleFonts.rubikBubbles(
                          color: Colors.orange,
                        ),
                      ))
                ],
              ),
            ),
          );
        });
  }

  void _createRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-9080800851774966/1093863893'
            : 'ca-app-pub-9080800851774966/7000796699',
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          onAdLoaded: (RewardedInterstitialAd ad) {
            print('$ad loaded.');
            _rewardedInterstitialAd = ad;
            _numRewardedInterstitialLoadAttempts = 0;
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('RewardedInterstitialAd failed to load: $error');
            _rewardedInterstitialAd = null;
            _numRewardedInterstitialLoadAttempts += 1;
            if (_numRewardedInterstitialLoadAttempts < maxFailedLoadAttempts) {
              _createRewardedInterstitialAd();
            }
          },
        ));
  }

  void _showRewardedInterstitialAd() {
    if (_rewardedInterstitialAd == null) {
      print('Warning: attempt to show rewarded interstitial before loaded.');
      return;
    }
    _rewardedInterstitialAd!.fullScreenContentCallback =
        FullScreenContentCallback(
      onAdShowedFullScreenContent: (RewardedInterstitialAd ad) =>
          print('$ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createRewardedInterstitialAd();
      },
      onAdFailedToShowFullScreenContent:
          (RewardedInterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createRewardedInterstitialAd();
      },
    );

    _rewardedInterstitialAd!.setImmersiveMode(true);
    _rewardedInterstitialAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print('$ad with reward $RewardItem(${reward.amount}, ${reward.type})');
      _updateMultiplier();
    });
    _rewardedInterstitialAd = null;
  }

  _updateMultiplier() {
    mulitplier++;
    setState(() {});
    Preferences.saveData("mulitplier", mulitplier);
  }
}
