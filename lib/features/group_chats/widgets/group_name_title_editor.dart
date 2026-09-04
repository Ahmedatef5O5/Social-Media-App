import 'package:flutter/material.dart';

class GroupNameTitleEditor extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController titleController;
  final String originalName;
  final String originalTitle;
  final bool isSavingName;
  final bool isSavingTitle;
  final VoidCallback onSaveName;
  final VoidCallback onSaveTitle;

  const GroupNameTitleEditor({
    super.key,
    required this.nameController,
    required this.titleController,
    required this.originalName,
    required this.originalTitle,
    required this.isSavingName,
    required this.isSavingTitle,
    required this.onSaveName,
    required this.onSaveTitle,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Group Name',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: nameController,
          builder: (context, _) {
            final currentText = nameController.text.trim();
            final isChanged =
                currentText.isNotEmpty && currentText != originalName;

            return TextField(
              controller: nameController,
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Group name',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
                suffixIcon:
                    isSavingName
                        ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: isChanged ? primary : Colors.grey.shade300,
                          ),
                          onPressed: isChanged ? onSaveName : null,
                          tooltip: 'Save Name',
                        ),
              ),
              onSubmitted: isChanged ? (_) => onSaveName() : null,
            );
          },
        ),
        const SizedBox(height: 20),

        Text(
          'Group Title',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: titleController,
          builder: (context, _) {
            final currentText = titleController.text.trim();
            final isChanged = currentText != originalTitle;

            return TextField(
              controller: titleController,
              style: const TextStyle(fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Add a title for this group',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
                suffixIcon:
                    isSavingTitle
                        ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                        : IconButton(
                          icon: Icon(
                            Icons.check_circle,
                            color: isChanged ? primary : Colors.grey.shade300,
                          ),
                          onPressed: isChanged ? onSaveTitle : null,
                          tooltip: 'Save Title',
                        ),
              ),
              onSubmitted: isChanged ? (_) => onSaveTitle() : null,
            );
          },
        ),
      ],
    );
  }
}
