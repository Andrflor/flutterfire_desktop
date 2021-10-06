// ignore_for_file: require_trailing_commas

part of firebase_auth_dart;

/// The options used for all requests made by [Auth] instance.
class AuthOptions {
  // ignore: public_member_api_docs
  AuthOptions({
    required this.apiKey,
    required this.projectId,
  });

  /// The API key used for all requests made by [Auth] instance.
  ///
  final String apiKey;

  /// The Id of GCP or Firebase project.
  ///
  final String projectId;
}

/// Pure Dart service wrapper around the Identity Platform REST API.
///
/// https://cloud.google.com/identity-platform/docs/use-rest-api
class Auth {
  // ignore: public_member_api_docs
  Auth({required this.options, http.Client? client})
      : assert(
          options.apiKey.isNotEmpty,
          'API key must not be empty, please provide a valid API key, '
          'or a dummy one if you are using the emulator.',
        ) {
    final _client = client ?? clientViaApiKey(options.apiKey);

    // Use auth emulator if available

    _identityToolkit = IdentityToolkitApi(_client).relyingparty;

    _idTokenChangedController = StreamController<User?>.broadcast(sync: true);
    _changeController = StreamController<User?>.broadcast(sync: true);
  }

  /// The settings this instance is configured with.
  final AuthOptions options;

  /// The currently signed in user for this instance.
  User? currentUser;

  /// The indentity toolkit API instance used to make all requests.
  late RelyingpartyResource _identityToolkit;

  // ignore: close_sinks
  late StreamController<User?> _changeController;

  // ignore: close_sinks
  late StreamController<User?> _idTokenChangedController;

  /// Sends events when the users sign-in state changes.
  ///
  /// If the value is `null`, there is no signed-in user.
  Stream<User?> get onAuthStateChanged {
    return _changeController.stream;
  }

  /// Sends events for changes to the signed-in user's ID token,
  /// which includes sign-in, sign-out, and token refresh events.
  ///
  /// If the value is `null`, there is no signed-in user.
  Stream<User?> get onIdTokenChanged {
    return _idTokenChangedController.stream;
  }

  /// Helper method to update currentUser and events.
  void _updateCurrentUserAndEvents(User? user) {
    currentUser = user;
    _changeController.add(user);
    _idTokenChangedController.add(user);
  }

  /// Sign in a user using email and password.
  ///
  /// Throws [AuthException] with following possible codes:
  ///
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final _response = await _identityToolkit.verifyPassword(
        IdentitytoolkitRelyingpartyVerifyPasswordRequest(
          returnSecureToken: true,
          password: password,
          email: email,
        ),
      );

      // Map the json response to an actual user.
      final user = User(_response.toJson(), this);

      _updateCurrentUserAndEvents(user);

      final providerId = AuthProvider.password.providerId;

      // Make a credential object based on the current sign-in method.
      return UserCredential(
        user: user,
        credential: AuthCredential(
          providerId: providerId,
          signInMethod: providerId,
        ),
        additionalUserInfo: AdditionalUserInfo(isNewUser: false),
      );
    } on DetailedApiRequestError catch (exception) {
      final authException = AuthException.fromErrorCode(exception.message);
      log('$authException', name: 'DartAuth/${authException.code}');

      throw authException;
    } catch (exception) {
      log('$exception', name: 'DartAuth');

      rethrow;
    }
  }

  /// Create new user using email and password.
  ///
  /// Throws [AuthException] with following possible codes:
  /// - `INVALID_EMAIL`
  /// - `EMAIL_EXISTS`
  /// - `OPERATION_NOT_ALLOWED`
  /// - `TOO_MANY_ATTEMPTS_TRY_LATER`
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final _response = await _identityToolkit.signupNewUser(
        IdentitytoolkitRelyingpartySignupNewUserRequest(
          email: email,
          password: password,
        ),
      );

      final user = User(_response.toJson(), this);
      _updateCurrentUserAndEvents(user);

      final providerId = AuthProvider.password.providerId;

      return UserCredential(
        user: user,
        credential: AuthCredential(
          providerId: providerId,
          signInMethod: providerId,
        ),
        additionalUserInfo: AdditionalUserInfo(isNewUser: true),
      );
    } on DetailedApiRequestError catch (exception) {
      final authException = AuthException.fromErrorCode(exception.message);
      log('$authException', name: 'DartAuth/${authException.code}');

      throw authException;
    } catch (exception) {
      log('$exception', name: 'DartAuth/signUpWithEmailAndPassword');

      rethrow;
    }
  }

  /// Fetch the list of providers associated with a specified email.
  ///
  /// Throws [AuthException] with following possible codes:
  /// - `INVALID_EMAIL`: user doesn't exist
  /// - `INVALID_IDENTIFIER`: the identifier isn't a valid email
  Future<List<String>> fetchSignInMethodsForEmail(String email) async {
    try {
      final _response = await _identityToolkit.createAuthUri(
        IdentitytoolkitRelyingpartyCreateAuthUriRequest(
          identifier: email,
          continueUri: 'http://localhost:8080/app',
        ),
      );

      return _response.allProviders ?? [];
    } on DetailedApiRequestError catch (exception) {
      final authException = AuthException.fromErrorCode(exception.message);
      log('$authException', name: 'DartAuth/${authException.code}');

      throw authException;
    } catch (exception) {
      log('$exception', name: 'DartAuth/fetchSignInMethodsForEmail');

      rethrow;
    }
  }

  /// Send a password reset email.
  ///
  /// Throws [AuthException] with following possible codes:
  /// - `EMAIL_NOT_FOUND`: user doesn't exist
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      final _response = await _identityToolkit.getOobConfirmationCode(
        Relyingparty(
          email: email,
          requestType: 'PASSWORD_RESET',
          // have to be sent, otherwise the user won't be redirected to the app.
          // continueUrl: ,
        ),
      );

      return _response.email;
    } on DetailedApiRequestError catch (exception) {
      final authException = AuthException.fromErrorCode(exception.message);
      log('$authException', name: 'DartAuth/${authException.code}');

      throw authException;
    } catch (exception) {
      log('$exception', name: 'DartAuth/sendPasswordResetEmail');

      rethrow;
    }
  }

  /// Verify password reset code and updates the password if all went good.
  /// `oldPassword` is optional, as this can be used to reset a password
  /// in case the user forgot the old one.
  ///
  /// Throws [AuthException] with following possible codes:
  /// - `OPERATION_NOT_ALLOWED`: Password sign-in is disabled for this project.
  /// - `EXPIRED_OOB_CODE`: The action code has expired.
  /// - `INVALID_OOB_CODE`: The action code is invalid. This can happen if the
  ///    code is malformed, expired, or has already been used.
  /// - `USER_DISABLED`: The user account has been disabled by an administrator.
  Future<String> resetUserPassword(
      {String? newPassword, String? oldPassword}) async {
    try {
      final _response = await _identityToolkit.setAccountInfo(
        IdentitytoolkitRelyingpartySetAccountInfoRequest(
          idToken: '',
        ),
      );

      return _response.email!;
    } on DetailedApiRequestError catch (exception) {
      final authException = AuthException.fromErrorCode(exception.message);
      log('$authException', name: 'DartAuth/${authException.code}');

      throw authException;
    } catch (exception) {
      log('$exception', name: 'DartAuth/resetPassword');

      rethrow;
    }
  }

  /// Send a sign in link to email.
  ///
  /// Throws [AuthException] with following possible codes:
  /// - `EMAIL_NOT_FOUND`: user doesn't exist
  Future<String?> sendSignInLinkToEmail(String email) async {
    try {
      final _response = await _identityToolkit.getOobConfirmationCode(
        Relyingparty(
          email: email,
          requestType: 'EMAIL_SIGNIN',
          // have to be sent, otherwise the user won't be redirected to the app.
          // continueUrl: ,
        ),
      );

      return _response.email;
    } on DetailedApiRequestError catch (exception) {
      final authException = AuthException.fromErrorCode(exception.message);
      log('$authException', name: 'DartAuth/${authException.code}');

      throw authException;
    } catch (exception) {
      log('$exception', name: 'DartAuth/sendSignInLinkToEmail');

      rethrow;
    }
  }

  /// Sign in anonymous users.
  ///
  Future<UserCredential> signInAnonymously() async {
    try {
      final _response = await _identityToolkit.signupNewUser(
        IdentitytoolkitRelyingpartySignupNewUserRequest(),
      );

      final _data = _response.toJson();

      final user = User(_data, this);
      _updateCurrentUserAndEvents(user);
      final providerId = AuthProvider.anonymous.providerId;

      return UserCredential(
        user: user,
        credential: AuthCredential(
          providerId: providerId,
          signInMethod: providerId,
        ),
        additionalUserInfo: AdditionalUserInfo(isNewUser: true),
      );
    } on DetailedApiRequestError catch (exception) {
      final authException = AuthException.fromErrorCode(exception.message);
      log('$authException', name: 'DartAuth/${authException.code}');

      throw authException;
    } catch (exception) {
      log('$exception', name: 'DartAuth/signInAnonymously');

      rethrow;
    }
  }

  /// Sign user out by cleaning currentUser, local persistence and all streams.
  ///
  Future<void> signOut() async {
    try {
      // TODO: figure out the correct sign-out flow
      _updateCurrentUserAndEvents(null);
    } catch (exception) {
      log('$exception', name: 'DartAuth/signOut');

      rethrow;
    }
  }

  /// Refresh a user ID token using the refreshToken,
  /// will refresh even if the token hasn't expired.
  ///
  Future<String?> refreshIdToken() async {
    try {
      return await _exchangeRefreshWithIdToken(
        currentUser!.refreshToken,
        options.apiKey,
      );
    } on HttpException catch (_) {
      rethrow;
    } catch (exception) {
      rethrow;
    }
  }

  Future<String?> _exchangeRefreshWithIdToken(
    String? refreshToken,
    String apiKey,
  ) async {
    final _response = await http.post(
      Uri.parse(
        'https://securetoken.googleapis.com/v1/token?key=$apiKey',
      ),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
      headers: {'Content-Typ': 'application/x-www-form-urlencoded'},
    );

    final Map<String, dynamic> _data = json.decode(_response.body);

    return _data['access_token'];
  }

  /// Use the emulator to perform all requests,
  /// check your terminal for the port being used.
  ///
  /// You must start the emulator in order to use it,
  /// the mthod will throw if there's no running emulator,
  /// see:
  /// https://firebase.google.com/docs/emulator-suite/install_and_configure#install_the_local_emulator_suite
  Future<Map> useEmulator({String host = 'localhost', int port = 9099}) async {
    // 1. Get the emulator project configs, it must be initialized first.
    // http://localhost:9099/emulator/v1/projects/{project-id}/config
    final localEmulator = Uri(
      scheme: 'http',
      host: host,
      port: port,
      path: '/emulator/v1/projects/${options.projectId}/config',
    );

    http.Response response;

    try {
      response = await http.get(localEmulator);
    } on SocketException catch (exception) {
      final socketException = SocketException(
        'Error happened while trying to connect to the local emulator, '
        'make sure you have it running, and you provided the correct port.',
        port: port,
        osError: exception.osError,
        address: exception.address,
      );

      log(socketException.message, name: 'DartAuth/useEmulator');

      throw socketException;
    } catch (exception) {
      log('$exception', name: 'DartAuth/useEmulator');
      rethrow;
    }

    final Map emulatorProjectConfig = json.decode(response.body);

    // 3. Update the requester to use emulator
    final rootUrl = 'http://$host:$port/www.googleapis.com/';
    _identityToolkit = IdentityToolkitApi(
      clientViaApiKey(options.apiKey),
      rootUrl: rootUrl,
    ).relyingparty;

    return emulatorProjectConfig;
  }
}
