import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  // IPv4 de tu PC en la red local + puerto 8080 de Spring Boot
  static const String baseUrl = 'http://192.168.1.71:8080';

  // 6.2 Función para pedir la lista de productos al endpoint GET /products
  Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Error ${response.statusCode}: no se pudieron cargar los productos',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos de Spring Boot'),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      // 6.3 FutureBuilder: espera la respuesta de la API y dibuja el resultado
      body: FutureBuilder<List<dynamic>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          // Mientras responde el servidor, mostrar indicador de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si hubo un error de conexión
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text('No hay productos registrados en la base de datos.'),
            );
          }

          // 6.4 Mostrar los elementos de la base de datos en una lista sencilla
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading:
                    const Icon(Icons.shopping_bag, color: Colors.pinkAccent),
                title: Text(product['name'].toString()),
                subtitle: Text('Stock: ${product['stock']}'),
                trailing: Text(
                  '\$${product['price']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
