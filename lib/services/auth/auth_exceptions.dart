//Login exceptions
class UserNotFoundAuthException implements Exception {}

class WrongPasswordAuthException implements Exception {}

//Register Exception\

class WeakPasswordAuthException implements Exception {}

class EmailAlreadyInUseAuthException implements Exception {}

class InvalidEmailAuthException implements Exception {}

//generic Exceptions

class GenericAuthException implements Exception {}

class UserNotLoggedInAuthException implements Exception {}
