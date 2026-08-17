import 'dart:async';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({
    super.key,
    required this.nextScreen,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController
      _animationController;

  late final Animation<double>
      _scaleAnimation;

  late final Animation<double>
      _fadeAnimation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 900,
      ),
    );

    _scaleAnimation =
        CurvedAnimation(
      parent:
          _animationController,
      curve:
          Curves.easeOutBack,
    );

    _fadeAnimation =
        CurvedAnimation(
      parent:
          _animationController,
      curve:
          Curves.easeIn,
    );

    _animationController
        .forward();

    _timer = Timer(
      const Duration(
        milliseconds: 1800,
      ),
      _continuar,
    );
  }

  void _continuar() {
    if (!mounted) {
      return;
    }

    Navigator.of(context)
        .pushReplacement(
      PageRouteBuilder(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return widget.nextScreen;
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity:
                animation,
            child:
                child,
          );
        },
        transitionDuration:
            const Duration(
          milliseconds: 450,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    _animationController
        .dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Scaffold(
      body: Container(
        width:
            double.infinity,
        height:
            double.infinity,
        decoration:
            BoxDecoration(
          gradient:
              LinearGradient(
            begin:
                Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.tertiary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child:
                FadeTransition(
              opacity:
                  _fadeAnimation,
              child:
                  Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  ScaleTransition(
                    scale:
                        _scaleAnimation,
                    child:
                        Container(
                      width:
                          112,
                      height:
                          112,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white
                                .withValues(
                          alpha:
                              0.16,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          34,
                        ),
                        border:
                            Border.all(
                          color:
                              Colors.white
                                  .withValues(
                            alpha:
                                0.25,
                          ),
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .explore_rounded,
                        size:
                            65,
                        color:
                            Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  const Text(
                    'GeoSense',
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          38,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing:
                          0.5,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Tus lugares, siempre contigo.',
                    style:
                        TextStyle(
                      color:
                          Colors.white70,
                      fontSize:
                          15,
                    ),
                  ),

                  const SizedBox(
                    height: 50,
                  ),

                  const SizedBox(
                    width: 28,
                    height: 28,
                    child:
                        CircularProgressIndicator(
                      strokeWidth:
                          2.5,
                      color:
                          Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}