import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:senemarket/constants.dart';
import 'package:senemarket/data/local/models/draft_product.dart';
import 'package:senemarket/domain/repositories/product_repository.dart';
import 'package:senemarket/presentation/views/drafts/edit_draft_page.dart';
import 'package:senemarket/presentation/views/drafts/viewmodel/edit_draft_viewmodel.dart';
import 'package:senemarket/presentation/widgets/global/navigation_bar.dart';

class MyDraftsPage extends StatefulWidget {
  const MyDraftsPage({Key? key}) : super(key: key);

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Box<DraftProduct> draftBox;

  @override
  void initState() {
    super.initState();
    draftBox = Hive.box<DraftProduct>('draft_products');
  }

  void _navigateToEditDraft(DraftProduct draft) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => EditDraftViewModel(context.read<ProductRepository>()),
          child: EditDraftPage(draft: draft),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drafts = draftBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Más reciente primero

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My drafts',
            style: TextStyle(
              fontFamily: 'Cabin',
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.black,
            )),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      bottomNavigationBar: const NavigationBarApp(selectedIndex: 4),
      body: drafts.isEmpty
          ? const Center(
        child: Text(
          'No drafts available.',
          style: TextStyle(
            fontFamily: 'Cabin',
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      )
          : ListView.builder(
        itemCount: drafts.length,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemBuilder: (context, index) {
          final draft = drafts[index];

          return Dismissible(
            key: Key(draft.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Delete Draft"),
                  content: const Text("Are you sure you want to delete this draft?"),
                  actions: [
                    TextButton(child: const Text("Cancel"), onPressed: () => Navigator.pop(context, false)),
                    TextButton(child: const Text("Delete"), onPressed: () => Navigator.pop(context, true)),
                  ],
                ),
              );

              if (confirm == true) {
                final deleted = draft;

                await deleted.delete();

                setState(() {
                  drafts.removeAt(index);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Draft '${deleted.name}' deleted"),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        await Hive.box<DraftProduct>('draft_products').put(deleted.id, deleted);
                        setState(() {
                          drafts.insert(index, deleted);
                        });
                      },
                    ),
                  ),
                );

                return true;
              }

              return false;
            },
            child: GestureDetector(
              onTap: () => _navigateToEditDraft(draft),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_rounded,
                        color: AppColors.primary30, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            draft.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Cabin',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Created: ${DateFormat.yMMMd().format(draft.createdAt)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontFamily: 'Cabin',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}