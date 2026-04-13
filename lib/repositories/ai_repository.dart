import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/error_handler.dart';

class SendAiMessageResult {
  final String conversationId;
  final String assistantMessage;
  final List<String> followUps;
  final Map<String, dynamic> triageResult;

  const SendAiMessageResult({
    required this.conversationId,
    required this.assistantMessage,
    required this.followUps,
    required this.triageResult,
  });

  factory SendAiMessageResult.fromJson(Map<String, dynamic> json) {
    return SendAiMessageResult(
      conversationId: json['conversationId'] as String? ?? '',
      assistantMessage: json['assistantMessage'] as String? ?? '',
      followUps:
          (json['followUps'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      triageResult: json['triageResult'] is Map<String, dynamic>
          ? json['triageResult'] as Map<String, dynamic>
          : const {},
    );
  }
}

class AiRepository {
  static const int _jwtRefreshLeadSeconds = 60;

  Future<Session> _requireValidSession({bool forceRefresh = false}) async {
    Session? session = supabase.auth.currentSession;

    if (forceRefresh || _isSessionNearExpiry(session)) {
      final refreshed = await supabase.auth.refreshSession();
      session = refreshed.session;
    }

    final hasUser = supabase.auth.currentUser != null;
    if (session == null || !hasUser) {
      throw const AppException(
        message: 'Your login session has expired. Please log in again.',
        code: 'not_authenticated',
      );
    }

    return session;
  }

  bool _isSessionNearExpiry(Session? session) {
    if (session == null) return true;

    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expiresAt <= nowSeconds + _jwtRefreshLeadSeconds;
  }

  Future<FunctionResponse> _invokeGeminiTriage(
    Map<String, dynamic> payload,
    String accessToken,
  ) {
    return supabase.functions.invoke(
      'gemini-triage',
      body: payload,
      headers: {'Authorization': 'Bearer $accessToken'},
    );
  }

  Future<List<Map<String, dynamic>>> listConversations({int limit = 20}) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      throw const AppException(message: 'Please log in to view chat history.');
    }

    try {
      final data = await supabase
          .from(Tables.aiConversations)
          .select('id, title, triage_result, created_at, updated_at')
          .eq('patient_id', uid)
          .order('updated_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load chat sessions: $e');
    }
  }

  Future<List<Map<String, dynamic>>> listMessages(String conversationId) async {
    try {
      final data = await supabase
          .from(Tables.aiMessages)
          .select('id, role, content, metadata, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to load chat messages: $e');
    }
  }

  Future<SendAiMessageResult> sendMessage({
    String? conversationId,
    required String message,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      throw const AppException(message: 'Message cannot be empty.');
    }

    try {
      var session = await _requireValidSession();

      final payload = <String, dynamic>{
        'message': trimmed,
        if (conversationId != null && conversationId.trim().isNotEmpty)
          'conversationId': conversationId.trim(),
      };

      FunctionResponse response;
      try {
        response = await _invokeGeminiTriage(payload, session.accessToken);
      } on FunctionException catch (firstAuthError) {
        final status = firstAuthError.status;
        if (status == 401 || status == 403) {
          session = await _requireValidSession(forceRefresh: true);
          response = await _invokeGeminiTriage(payload, session.accessToken);
        } else {
          rethrow;
        }
      }

      final raw = response.data;
      if (raw is! Map) {
        throw const AppException(
          message: 'Unexpected response from AI service. Please try again.',
        );
      }

      final body = Map<String, dynamic>.from(raw);
      final success = body['success'] == true;
      if (!success) {
        final error = body['error']?.toString() ?? 'AI service unavailable.';
        throw AppException(message: error);
      }

      final data = body['data'];
      if (data is! Map) {
        throw const AppException(
          message: 'AI response payload missing required data.',
        );
      }

      final result = SendAiMessageResult.fromJson(
        Map<String, dynamic>.from(data),
      );

      if (result.conversationId.trim().isEmpty) {
        throw const AppException(
          message: 'AI response missing conversation id.',
        );
      }

      return result;
    } on AppException {
      rethrow;
    } on FunctionException catch (e) {
      final status = e.status;
      if (status == 404) {
        throw const AppException(
          message:
              'AI backend is not deployed yet. Deploy Edge Function "gemini-triage" in Supabase (Edge Functions) and try again.',
          code: 'function_not_found',
        );
      }

      if (status == 401 || status == 403) {
        throw AppException(
          message:
              'AI backend rejected the request (auth). Please log in again and verify function JWT settings.',
          code: 'function_auth_error',
        );
      }

      final detailsText = e.details.toString();
      final hasDetails = detailsText.isNotEmpty && detailsText != 'null';
      final functionMessage = hasDetails ? detailsText : e.reasonPhrase;

      throw AppException(
        message: 'AI backend error (${e.status}): $functionMessage',
        code: 'function_error',
      );
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(
        message:
            'Failed to send AI message. Ensure the `gemini-triage` Edge Function is deployed and secrets are configured. Error: $e',
      );
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) {
      throw const AppException(
        message: 'Please log in to manage chat sessions.',
      );
    }

    try {
      await supabase
          .from(Tables.aiConversations)
          .delete()
          .eq('id', conversationId)
          .eq('patient_id', uid);
    } on PostgrestException catch (e) {
      throw AppException.fromPostgrestException(e);
    } catch (e) {
      throw AppException(message: 'Failed to delete chat session: $e');
    }
  }
}
