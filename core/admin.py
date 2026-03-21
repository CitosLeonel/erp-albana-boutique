from django.contrib import admin
from .models import Cliente, Categoria, Producto, Variante, Pedido, ItemPedido

@admin.register(Cliente)
class ClienteAdmin(admin.ModelAdmin):
    list_display = ('nombre', 'telefono', 'email')
    search_fields = ('nombre', 'telefono', 'email')

@admin.register(Categoria)
class CategoriaAdmin(admin.ModelAdmin):
    list_display = ('nombre',)

@admin.register(Producto)
class ProductoAdmin(admin.ModelAdmin):
    list_display = ('nombre', 'categoria', 'precio')
    list_filter = ('categoria',)
    search_fields = ('nombre',)

@admin.register(Variante)
class VarianteAdmin(admin.ModelAdmin):
    list_display = ('producto', 'talle', 'color', 'stock')
    list_filter = ('producto__categoria', 'talle', 'color')
    search_fields = ('producto__nombre',)

@admin.register(Pedido)
class PedidoAdmin(admin.ModelAdmin):
    list_display = ('id', 'cliente', 'fecha', 'total', 'estado', 'pagado')
    list_filter = ('estado', 'pagado', 'fecha')
    search_fields = ('cliente__nombre',)

admin.site.register(ItemPedido)