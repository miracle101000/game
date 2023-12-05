import 'dart:io';
import 'dart:math';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';

class Body extends StatefulWidget {
  final PageController pageController;
  const Body({super.key, required this.pageController});

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  int count = 0;
  Color color = Colors.orangeAccent.shade700;
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  RewardedInterstitialAd? _rewardedInterstitialAd;
  int _numRewardedInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;

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
    _rewardedInterstitialAd?.dispose();
    audioPlayer.dispose();
  }

  init() async {
    count = await Preferences.getData("count") ?? 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
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
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, color])),
        child: Center(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.02,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    count.toString(),
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
                    valueColor: const AlwaysStoppedAnimation(Colors.orange),
                    backgroundColor: Colors.black38,
                    borderColor: Colors.transparent,
                    borderWidth: 0.0,
                    borderRadius: 12.0,
                    direction: Axis.vertical,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (Platform.isAndroid) {
                    audioPlayer.setPitch(generateRandomNumber().toDouble());
                  }
                  if (count < 10000000) {
                    await Future.wait([
                      Future(() {
                        count++;
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
                    if (count % 50 == 0) {
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
        request: const AdRequest(
          keywords: <String>['game', 'videogame'],
          // contentUrl: 'http://foo.com/bar.html',
          nonPersonalizedAds: false,
        ),
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
    });
    _rewardedInterstitialAd = null;
  }
}
