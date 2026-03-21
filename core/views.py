from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.db import transaction
from .models import Cliente, Producto, Variante, Pedido, ItemPedido
from django.db.models import Q

@login_required
def nueva_venta(request):
    if request.method == 'POST':
        try:
            with transaction.atomic():
                # Obtener o crear cliente (por ahora usamos ID)
                cliente_id = request.POST.get('cliente')
                if not cliente_id:
                    messages.error(request, "Debes seleccionar un cliente.")
                    return redirect('nueva_venta')

                cliente = Cliente.objects.get(id=cliente_id)

                # Crear el pedido
                pedido = Pedido.objects.create(
                    cliente=cliente,
                    total=0,  # se actualizará después
                    estado='pendiente',
                    pagado=False,
                    notas=request.POST.get('notas', '')
                )

                total = 0

                # Procesar líneas de productos
                indices = request.POST.getlist('producto_index')  # lista de índices para múltiples líneas
                for idx in indices:
                    producto_id = request.POST.get(f'producto_{idx}')
                    variante_id = request.POST.get(f'variante_{idx}')
                    cantidad = int(request.POST.get(f'cantidad_{idx}', 0))

                    if cantidad <= 0 or not variante_id:
                        continue

                    variante = Variante.objects.select_for_update().get(id=variante_id)

                    if variante.stock < cantidad:
                        raise ValueError(f"No hay suficiente stock de {variante} (disponible: {variante.stock})")

                    precio_unitario = variante.producto.precio  # o el precio real si varía

                    ItemPedido.objects.create(
                        pedido=pedido,
                        variante=variante,
                        cantidad=cantidad,
                        precio_unitario=precio_unitario
                    )

                    # Restar stock
                    variante.stock -= cantidad
                    variante.save()

                    total += cantidad * precio_unitario

                # Actualizar total del pedido
                pedido.total = total
                pedido.save()

                messages.success(request, f"Venta registrada con éxito. Total: ${total:,.2f}")
                return redirect('dashboard')

        except Exception as e:
            messages.error(request, f"Error al registrar la venta: {str(e)}")
            return redirect('nueva_venta')

    # GET - mostrar formulario
    clientes = Cliente.objects.all().order_by('nombre')
    productos = Producto.objects.all().order_by('nombre')

    context = {
        'titulo': 'Nueva Venta Rápida',
        'clientes': clientes,
        'productos': productos,
    }
    return render(request, 'ventas/nueva_venta.html', context)