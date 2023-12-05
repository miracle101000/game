import 'dart:io';
import 'package:animated_background/animated_background.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game/preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

import 'notification_service.dart';

class Intro extends StatefulWidget {
  final PageController controller;
  const Intro({super.key, required this.controller});

  @override
  State<Intro> createState() => _IntroState();
}

class _IntroState extends State<Intro> with TickerProviderStateMixin {
  AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  InterstitialAd? _interstitialAd;
  int _numInterstitialLoadAttempts = 0;
  int maxFailedLoadAttempts = 3;
  @override
  void initState() {
    super.initState();
    init();
    audioPlayer.open(Audio("assets/sound/play.wav"),
        autoStart: false, showNotification: false);
    _createInterstitialAd();
  }

  @override
  void dispose() {
    super.dispose();
    _interstitialAd?.dispose();
    audioPlayer.dispose();
  }

  init() async {
    bool isInit = (await Preferences.getData("init")) ?? false;
    if (!isInit) {
      Preferences.saveData("init", true);
      NotificationService().scheduleNotification(
          title: '10,000,000 Clicks',
          body: "🌟 Time to Unwind! 🎮",
          scheduledNotificationDateTime:
              DateTime.now().add(Duration(seconds: 10)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        AnimatedBackground(
          behaviour: RandomParticleBehaviour(
              options: ParticleOptions(baseColor: Colors.orange.shade900)),
          vsync: this,
          child: Padding(
            padding: const EdgeInsets.only(top: 56.0, bottom: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.85,
                  child: AutoSizeText(
                    "10,000,000 Clicks",
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: GoogleFonts.rubikBubbles(
                        color: Colors.white, fontSize: 30),
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                _playButton()
              ],
            ),
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).viewPadding.bottom + 32,
          child: CupertinoButton(
            onPressed: () async {
              await _launchUrl(
                  "https://github.com/miracle101000/tap_infinity/blob/main/privacy.md");
            },
            child: Text(
              "Terms & Privacy policy",
              style: GoogleFonts.urbanist(
                  fontStyle: FontStyle.italic, color: Colors.white),
            ),
          ),
        )
      ],
    );
  }

  Future<void> _launchUrl(String l) async {
    if (!await launchUrl(Uri.parse(l), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $l');
    }
  }

  _playButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ZoomTapAnimation(
          child: CupertinoButton(
            onPressed: () async {
              Future.wait([
                Future(() async => _playButtonSound()),
                Future(() async => widget.controller.animateToPage(1,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut)),
                Future(() async => HapticFeedback.heavyImpact())
              ]);
            },
            child: Container(
              height: 50,
              width: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: -Alignment.bottomLeft,
                      end: -Alignment.bottomRight,
                      colors: [Colors.orange.shade900, Colors.orange]),
                  borderRadius: BorderRadius.circular(5)),
              child: Text(
                "PLay",
                style:
                    GoogleFonts.rubikBubbles(color: Colors.white, fontSize: 30),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future _playButtonSound() async {
    await audioPlayer.playOrPause();
  }

  void _createInterstitialAd() {
    InterstitialAd.load(
        adUnitId: Platform.isAndroid
            ? 'ca-app-pub-9080800851774966/4162880362'
            : 'ca-app-pub-9080800851774966/7564699633',
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$ad loaded');
            _interstitialAd = ad;
            _numInterstitialLoadAttempts = 0;
            _interstitialAd!.setImmersiveMode(true);
            Future.delayed(Duration(seconds: 2)).then((value) async {
              await _showInterstitialAd();
            });
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('InterstitialAd failed to load: $error.');
            _numInterstitialLoadAttempts += 1;
            _interstitialAd = null;
            if (_numInterstitialLoadAttempts < maxFailedLoadAttempts) {
              _createInterstitialAd();
            }
          },
        ));
  }

  Future _showInterstitialAd() async {
    if (_interstitialAd == null) {
      print('Warning: attempt to show interstitial before loaded.');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) =>
          print('ad onAdShowedFullScreenContent.'),
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        print('$ad onAdDismissedFullScreenContent.');
        ad.dispose();
        _createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        _createInterstitialAd();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }
}
