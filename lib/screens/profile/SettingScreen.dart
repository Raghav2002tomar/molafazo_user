import 'dart:io';

import 'package:ecom/screens/onboarding/OnBoardingScreen.dart';
import 'package:ecom/services/api_service.dart';
import 'package:ecom/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/translate_provider.dart';
import 'controller/profile_service.dart';
import 'controller/user_storage.dart';
import 'model/user_model.dart';


class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool isMale = true;
  bool notification = true;
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final ageCtrl = TextEditingController();

  File? profileImage;
  UserModel? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    user = await UserStorage.getUser();
    if (user != null) {
      nameCtrl.text = user!.name;
      emailCtrl.text = user!.email;
    }
    setState(() => loading = false);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => profileImage = File(picked.path));
    }
  }
  Future<void> _updateProfile() async {
    try {
      await ProfileService.updateProfile(
        name: nameCtrl.text,
        email: emailCtrl.text,
        image: profileImage,
      );

      Navigator.pop(context, true); // refresh previous screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: _CircleAction(
            icon: Icons.keyboard_double_arrow_left_outlined,
            bg: isDark ? Colors.white : Colors.black,
            fg: isDark ? Colors.black : Colors.white,
            onTap: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          "Profile Edit",
          style: TextStyle(
            color: cs.onBackground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Image
              Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                   child:   GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: profileImage != null
                                ? FileImage(profileImage!)
                                : (user?.profilePhoto != null
                                ? NetworkImage("${ApiService.ImagebaseUrl}${ApiService.profile_image_URL}${user!.profilePhoto!}")
                                : const AssetImage('assets/avatar.png')) as ImageProvider,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: cs.primary,
                              child: Icon(Icons.edit, size: 16, color: cs.onPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),


                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Upload image",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onBackground,
                ),
              ),
              const SizedBox(height: 24),

              // Name
              _buildEditableField("Name", nameCtrl, cs),
              const SizedBox(height: 16),

              // Gender
              // Align(
              //   alignment: Alignment.centerLeft,
              //   child: Text("Gender",
              //       style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
              // ),
              // const SizedBox(height: 8),
              // Row(
              //   children: [
              //     _genderButton("Male", true),
              //     const SizedBox(width: 12),
              //     _genderButton("Female", false),
              //   ],
              // ),
              // const SizedBox(height: 16),

              // // Age
              // _buildTextField("Age", "22 Year", cs),
              // const SizedBox(height: 16),

              // Email
              _buildEditableField("Email", emailCtrl, cs),
              const SizedBox(height: 24),

              // Settings
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Language (Popup Menu)
              _buildSettingsItem(
                icon: Icons.language,
                title: "Language",
                trailing: PopupMenuButton<String>(
                  onSelected: (lang) {
                    context.read<TranslateProvider>().setLocale(lang);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'en', child: Text('English')),
                    PopupMenuItem(value: 'ru', child: Text('Русский')),
                    PopupMenuItem(value: 'tg', child: Text('Тоҷикӣ')),
                  ],
                  icon: const Icon(Icons.arrow_drop_down),
                ),
              ),

              // Notification toggle
              _buildSettingsItem(
                icon: Icons.notifications_none,
                title: "Notification",
                trailing: Switch(
                  value: notification,
                  onChanged: (val) => setState(() => notification = val),
                ),
              ),

              // Dark mode toggle (from Provider)
              _buildSettingsItem(
                icon: Icons.dark_mode_outlined,
                title: "Dark Mode",
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) => context.read<ThemeProvider>().toggle(),
                ),
              ),

              // Help center
              _buildSettingsItem(
                icon: Icons.help_outline,
                title: "Help Center",
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),

              const SizedBox(height: 24),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

              const SizedBox(height: 24),


              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark?Colors.white:  Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    AuthStorage.logout();
                    // TODO: Logout action

                    Navigator
                        .of(context)
                        .pushReplacement(new MaterialPageRoute(builder: (BuildContext context) {
                      return new OnBoardingScreen();
                    }));
                  },
                  icon:  Icon(Icons.logout, color:isDark?Colors.black:  Colors.white),
                  label:  Text(
                    "Log Out",
                    style: TextStyle(color: isDark?Colors.black:  Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value, ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: cs.outline.withOpacity(0.2)),
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onBackground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderButton(String text, bool male) {
    final cs = Theme.of(context).colorScheme;
    final selected = male == isMale;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => isMale = male),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cs.onBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.onBackground.withOpacity(0.4)),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? cs.background : cs.onBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _CircleAction(
            icon: icon,
            bg: isDark ? Colors.white : Colors.black,
            fg: isDark ? Colors.black : Colors.white,
            onTap: () {},
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title,
                style: TextStyle(
                    color: cs.onBackground, fontWeight: FontWeight.w700)),
          ),
          trailing,
        ],
      ),
    );
  }
}
Widget _buildEditableField(
    String label,
    TextEditingController controller,
    ColorScheme cs,
    ) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
      TextField(
        controller: controller,
        decoration: const InputDecoration(border: UnderlineInputBorder()),
      ),
    ],
  );
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
  const _CircleAction({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: fg, size: 20),
        ),
      ),
    );
  }
}
