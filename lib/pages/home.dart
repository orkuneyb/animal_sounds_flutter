import 'package:animal_sounds_flutter/models/animal.dart';
import 'package:animal_sounds_flutter/pages/animal_details.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final imageUrl =
      "https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Lion_d%27Afrique.jpg/825px-Lion_d%27Afrique.jpg?20150506193838";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 sütun
        ),
        itemCount: 10,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AnimalDetailsPage(
                          animal: Animal(),
                        )),
              );
            },
            child: Card(
              child: Column(
                children: [
                  Image.network(
                    imageUrl,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text("resim yüklenemedi"),
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      Animal().name.toString(),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Bu hayvanın açıklaması burada yer alacak',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  AppBar appBarWidget() {
    return AppBar(
      centerTitle: true,
      title: const Text(
        "Hayvan Sesleri",
      ),
      leading: const Icon(
        Icons.menu,
      ),
      actions: const [
        Icon(
          Icons.settings,
        )
      ],
    );
  }
}
