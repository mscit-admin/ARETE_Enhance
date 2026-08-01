import 'package:flutter/material.dart';

/// Key for the AppShell's root Scaffold. Screen headers use it to open the
/// account drawer on the *outer* scaffold, so the menu covers the whole
/// screen — including the bottom navigation bar and the centre button.
final GlobalKey<ScaffoldState> rootScaffoldKey = GlobalKey<ScaffoldState>();
