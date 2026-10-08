import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'firestore_service.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirestoreService();

  Future<AppUser> entrar(String email, String senha, {required String perfil}) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: senha);
    final u = await _buscarPerfil(cred.user!.uid, email);
    if (u == null) {
      await _auth.signOut();
      throw FirebaseAuthException(code: 'perfil-nao-encontrado');
    }
    if (u.tipoPerfil != perfil) {
      await _auth.signOut();
      throw FirebaseAuthException(code: 'perfil-incorreto');
    }
    return u;
  }

  /// Procura o perfil pelo uid do Auth. Se não achar, procura pelo e-mail:
  /// é assim que os usuários mockados do grupo (uid_marina_01 etc.) entram.
  Future<AppUser?> _buscarPerfil(String uid, String email) async {
    final porUid = await _db.usuario(uid);
    if (porUid != null) return porUid;
    final q = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return q.docs.isEmpty ? null : AppUser.fromDoc(q.docs.first);
  }

  Future<AppUser> cadastrar({
    required String nome,
    required String email,
    required String senha,
    required String perfil, // 'consumidor' ou 'brecho'
    bool lojaFisica = true,
    String rua = '',
    String telefone = '',
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: senha);
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(nome);

    final u = AppUser(
      id: uid,
      nome: nome,
      email: email,
      tipoPerfil: perfil,
      telefone: telefone.isEmpty ? null : telefone,
    );
    await _db.salvarUsuario(u);

    if (perfil == 'brecho') {
      final ref = FirebaseFirestore.instance.collection('stores').doc();
      await ref.set({
        'id': ref.id,
        'owner_id': uid,
        'nome': nome,
        'descricao': '',
        'estilos': <String>[],
        'ativa': true,
        'verificada': false,
        'tipo_atendimento': lojaFisica ? 'fisico' : 'online',
        'endereco': {'logradouro': rua},
        'whatsapp': telefone,
        'criado_em': FieldValue.serverTimestamp(),
      });
    }
    return u;
  }

  Future<void> sair() => _auth.signOut();

  static String mensagemDeErro(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'user-not-found':
        case 'wrong-password':
          return 'E-mail ou senha incorretos.';
        case 'email-already-in-use':
          return 'Já existe uma conta com esse e-mail.';
        case 'weak-password':
          return 'A senha precisa ter pelo menos 6 caracteres.';
        case 'invalid-email':
          return 'Esse e-mail não parece válido.';
        case 'network-request-failed':
          return 'Sem conexão. Confira a internet e tente de novo.';
        case 'perfil-incorreto':
          return 'Essa conta é de outro tipo de perfil. Volte e escolha a opção certa.';
        case 'perfil-nao-encontrado':
          return 'Não achamos o perfil dessa conta no banco.';
        case 'permission-denied':
          return 'Sem permissão no banco. Confira as regras do Firestore.';
      }
    }
    return 'Algo deu errado. Tente de novo.';
  }
}