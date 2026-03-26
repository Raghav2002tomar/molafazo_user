import 'package:flutter/material.dart';

import 'controller/CityService.dart';


class CitySearchScreen extends StatefulWidget {
  final String? type;
  const CitySearchScreen({super.key,  this.type});

  @override
  State<CitySearchScreen> createState() => _CitySearchScreenState();
}

class _CitySearchScreenState extends State<CitySearchScreen> {

  final TextEditingController searchController = TextEditingController();

  List<CityModel> allCities = [];
  List<CityModel> filteredCities = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchCities();
  }

  /// FETCH CITY LIST
  Future<void> fetchCities() async {

    setState(() {
      loading = true;
    });

    final cities = await CityService().fetchCities();

    setState(() {
      allCities = cities;
      filteredCities = cities;
      loading = false;
    });
  }

  /// SEARCH CITY
  void searchCity(String query) {

    if (query.isEmpty) {
      setState(() {
        filteredCities = allCities;
      });
      return;
    }

    final result = allCities.where((city) {

      return city.name
          .toLowerCase()
          .contains(query.toLowerCase());

    }).toList();

    setState(() {
      filteredCities = result;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Select City"),
      ),

      body: Column(
        children: [

          /// SEARCH FIELD
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: searchCity,
              decoration: InputDecoration(
                hintText: "Search city...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          /// LOADING
          if (loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )

          else

          /// CITY LIST
            Expanded(
              child: ListView(
                children: [

                  /// 🌍 ALL CITIES OPTION
               if(widget.type.toString() != "address")   ListTile(
                    leading: const Icon(Icons.public),
                    title: const Text(
                      "All Cities",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {

                      await CityStorage.removeCity();

                      Navigator.pop(context, {
                        "id": null,
                        "name": "All Cities"
                      });
                    },
                  ),

                  const Divider(),

                  ...filteredCities.map((city) {
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(
                        city.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {

                        await CityStorage.saveCity(city.id, city.name);

                        Navigator.pop(context, {
                          "id": city.id,
                          "name": city.name
                        });

                      },
                    );
                  }).toList(),
                ],
              ),
            )        ],
      ),
    );
  }
}