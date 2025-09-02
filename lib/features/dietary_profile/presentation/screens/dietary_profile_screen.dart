import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recette/features/dietary_profile/data/utils/profile_parser.dart';
import 'package:recette/features/dietary_profile/presentation/controllers/dietary_profile_controller.dart';

class DietaryProfileScreen extends StatefulWidget {
  const DietaryProfileScreen({super.key});

  @override
  State<DietaryProfileScreen> createState() => _DietaryProfileScreenState();
}

class _DietaryProfileScreenState extends State<DietaryProfileScreen>
    with SingleTickerProviderStateMixin {
  late final DietaryProfileController _controller;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = DietaryProfileController();
    _controller.loadProfile(); // Start the initial data load
    _tabController = TabController(length: 2, vsync: this);
    // This listener is for the UI only, to rebuild the 'Visual' tab
    _controller.textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<DietaryProfileController>(
        builder: (context, controller, child) {
          // The UI reads the text from the controller to parse it
          final parsedCategories =
              ProfileParser.parse(controller.textController.text);

          return Scaffold(
            appBar: AppBar(
              title: const Text('My Dietary Profile'),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.article), text: 'Markdown'),
                  Tab(icon: Icon(Icons.list_alt), text: 'Visual'),
                ],
              ),
            ),
            bottomNavigationBar: BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      // Delegate the action to the controller
                      final jobStarted = await controller.runAiReview();
                      if (mounted && jobStarted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'AI review started... Track progress in the Jobs Tray.'),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Profile is empty. Nothing to review.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('AI Review'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    // Read the saving state from the controller
                    onPressed: controller.isSaving
                        ? null
                        : () async {
                            // Delegate saving to the controller
                            await controller.saveProfile();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Profile saved successfully!'),
                                    backgroundColor: Colors.green),
                              );
                            }
                          },
                    // Read the saving state from the controller
                    icon: controller.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
            // Read the loading state from the controller
            body: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Markdown Editor Tab
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          // Use the text controller from the controller
                          controller: controller.textController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            hintText:
                                '## Sugar\n- Prioritize foods with 0g of added sugar...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),

                      // Visual Editor Tab
                      ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: parsedCategories.length,
                        itemBuilder: (context, index) {
                          final category = parsedCategories[index];
                          return Card(
                            elevation: 2,
                            margin:
                                const EdgeInsets.symmetric(vertical: 4.0),
                            child: ExpansionTile(
                              title: Text(category.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              initiallyExpanded: true,
                              children: category.rules.map((rule) {
                                return ListTile(
                                  contentPadding: EdgeInsets.only(
                                      left: 16.0 + (rule.indentation * 16.0),
                                      right: 16.0),
                                  title: Text(rule.text),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}