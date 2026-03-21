from django.contrib import admin
from django.urls import path
from django.contrib.auth import views as auth_views   # Para login/logout por defecto de Django
from core.views import dashboard                      # Importamos la vista dashboard que creamos
from core.views import dashboard, nueva_venta

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # Dashboard (home del sitio, solo para usuarios logueados)
    path('', dashboard, name='dashboard'),
    
    # Login y logout (usamos los views integrados de Django)
    path('accounts/login/', auth_views.LoginView.as_view(template_name='registration/login.html'), name='login'),
    path('accounts/logout/', auth_views.LogoutView.as_view(next_page='login'), name='logout'),
    
    # Opcional: si más adelante agregamos reset de password u otras auth views
    # path('accounts/password_reset/', auth_views.PasswordResetView.as_view(), name='password_reset'),

    path('', dashboard, name='dashboard'),
    path('nueva-venta/', nueva_venta, name='nueva_venta'),
]