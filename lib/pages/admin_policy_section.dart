part of 'admin_page.dart';

class _PolicyAdminSection extends StatelessWidget {
  const _PolicyAdminSection({
    required this.policies,
    required this.loading,
    required this.onSave,
  });

  final List<SitePolicy> policies;
  final bool loading;
  final Future<void> Function(SitePolicy) onSave;

  Future<void> _edit(BuildContext context, SitePolicy policy) async {
    final updated = await showModalBottomSheet<SitePolicy>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFEF5E6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _PolicyEditor(policy: policy),
    );
    if (updated != null) await onSave(updated);
  }

  @override
  Widget build(BuildContext context) {
    final savedBySlug = {for (final policy in policies) policy.slug: policy};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Site Policies',
          style: GoogleFonts.dmSerifDisplay(
            fontSize: 38,
            color: const Color(0xFF5B351A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Edit the public privacy, terms, and refund pages.',
          style: GoogleFonts.ibmPlexSans(fontSize: 18),
        ),
        const SizedBox(height: 18),
        for (final policy in defaultPolicies.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PolicyAdminCard(
              policy: savedBySlug[policy.slug] ?? policy,
              loading: loading,
              onEdit: () => _edit(context, savedBySlug[policy.slug] ?? policy),
            ),
          ),
      ],
    );
  }
}

class _PolicyAdminCard extends StatelessWidget {
  const _PolicyAdminCard({
    required this.policy,
    required this.loading,
    required this.onEdit,
  });

  final SitePolicy policy;
  final bool loading;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFECE7DD),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: loading ? null : onEdit,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD5B48A)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_outlined, color: Color(0xFF914B0D)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    policy.title,
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 25,
                      color: const Color(0xFF5B351A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '/${policy.slug}',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 16,
                      color: const Color(0xFF765F4B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined),
          ],
        ),
      ),
    ),
  );
}

class _PolicyEditor extends StatefulWidget {
  const _PolicyEditor({required this.policy});

  final SitePolicy policy;

  @override
  State<_PolicyEditor> createState() => _PolicyEditorState();
}

class _PolicyEditorState extends State<_PolicyEditor> {
  late final TextEditingController _title;
  late final TextEditingController _content;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.policy.title);
    _content = TextEditingController(text: widget.policy.content);
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    final content = _content.text.trim();
    if (title.isEmpty || content.isEmpty) return;
    Navigator.pop(
      context,
      SitePolicy(slug: widget.policy.slug, title: title, content: content),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        14,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6C0AA),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Edit ${widget.policy.title}',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 32,
                color: const Color(0xFF5B351A),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Page title'),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: TextField(
                controller: _content,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Policy text',
                  helperText: 'Use a blank line between paragraphs.',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save policy'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
