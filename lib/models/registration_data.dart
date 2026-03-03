class RegistrationData {
  String? fullName;
  String? email;
  String? dobIso;
  String? gender;
  String? phoneNumber;
  String? phoneOtp;
  String? aadhaarNumber;
  String? streetAddress;
  String? city;
  String? pinCode;
  String? state;

  RegistrationData({
    this.fullName,
    this.email,
    this.dobIso,
    this.gender,
    this.phoneNumber,
    this.phoneOtp,
    this.aadhaarNumber,
    this.streetAddress,
    this.city,
    this.pinCode,
    this.state,
  });

  Map<String, dynamic> toJson() {
    return {
      "fullName": fullName?.trim(),
      "email": email?.toLowerCase().trim(),
      "dateOfBirth": dobIso,
      "gender": gender,
      "phone": phoneNumber?.trim(),
      "otp": null,
      "address": {
        "street": streetAddress?.trim(),
        "city": city?.trim(),
        "state": state?.trim(),
        "pinCode": pinCode?.trim(),
      },
    };
  }
}
