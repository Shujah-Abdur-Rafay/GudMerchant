// ignore_for_file: non_constant_identifier_names

class UserModel{
  final String uID;
  final String username; 
  final String email;
  final String phone;
  final String userImg;
  final String userDeviceToken;
  final String country;
  final String userAdress;  
  final String street;
  final bool isAdmin;
  final bool isActive;
  final bool isPhoneVerified;
  final dynamic CreatedOn;

UserModel({
  
 required this.uID,
  required this.username, 
  required this.email,
  required this.phone,
  required this.userImg,
  required this.userDeviceToken,
  required this.country,
  required this.userAdress,  
  required this.street,
  required this.isAdmin,
  required this.isActive,
  required this.CreatedOn,
  this.isPhoneVerified = false,

});

  Map<String, dynamic> toMap(){
    return{
      'uID':uID,
      'username':username,
      'email':email,
      'phone':phone,
      'userImg':userImg,
      'userDeviceToken':userDeviceToken,
      'country':country,
      'userAdress':userAdress,
      'street':street,
      'isAdmin': isAdmin,
      'isActive':isActive,
      'isPhoneVerified': isPhoneVerified,
      'CreatedOn':CreatedOn
    };
  }

  factory UserModel.fromMap(Map<String,dynamic>json){
    try {
      return UserModel(
        uID:            json['uID'] ?? '',
        username:       json['username'] ?? 'User',
        email:          json['email'] ?? '',
        phone:          json['phone'] ?? '',
        userImg:        json['userImg'] ?? '',
        userDeviceToken: json['userDeviceToken'] ?? '',
        country:        json['country'] ?? '',
        userAdress:     json['userAdress'] ?? '',
        street:         json['street'] ?? '',
        isAdmin:        json['isAdmin'] ?? false,
        isActive:       json['isActive'] ?? true,
        isPhoneVerified: json['isPhoneVerified'] ?? false,
        CreatedOn:      json['CreatedOn']?.toString() ?? DateTime.now().toString()
      );
    } catch (e) {
      print('Error parsing UserModel: $e');
      // Return a default user model instead of crashing
      return UserModel(
        uID: json['uID'] ?? '',
        username: 'Error User',
        email: '',
        phone: '',
        userImg: '',
        userDeviceToken: '',
        country: '',
        userAdress: '',
        street: '',
        isAdmin: false,
        isActive: true,
        isPhoneVerified: false,
        CreatedOn: DateTime.now().toString(),
      );
    }
  }
}