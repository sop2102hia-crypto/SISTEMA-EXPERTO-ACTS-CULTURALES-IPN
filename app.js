const BASE_URL = 'http://localhost:8080';

// Lógica para solicitar recomendaciones
document.getElementById('form-recomendacion').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const categoria = document.getElementById('categoria').value;
    const habilidad = document.getElementById('habilidad').value;
    const interes = document.getElementById('interes').value;
    const grupal = document.getElementById('grupal').value;

    const divResultado = document.getElementById('resultado-recomendacion');
    divResultado.style.display = 'block';
    divResultado.innerHTML = '<div class="spinner">Consultando motor de inferencia...</div>';

    try {
        const url = new URL(`${BASE_URL}/api/recomendar`);
        url.search = new URLSearchParams({ categoria, habilidad, interes, grupal }).toString();

        const respuesta = await fetch(url);
        const datos = await respuesta.json();

        if (datos.status === 'ok') {
            let htmlContenido = '<h3>🎯 Actividades Recomendadas:</h3>';
            datos.recomendaciones.forEach(act => {
                let htmlBeca = '';
                act.becas.forEach(b => {
                    htmlBeca += `<li><b>${b.tipo}:</b> ${b.requisito}</li>`;
                });
                
                htmlContenido += `
                    <div class="actividad-card">
                        <h4>${act.nombre}</h4>
                        <ul>${htmlBeca || '<li>Sin becas aplicables</li>'}</ul>
                    </div>
                `;
            });
            divResultado.innerHTML = htmlContenido;
        } else {
            divResultado.innerHTML = `
                <div style="color: #f87171; background: #7f1d1d33; padding: 12px; border-radius: 6px; border: 1px solid #7f1d1d;">
                    <b>Aviso del Sistema Experto:</b> ${datos.mensaje} <br><small style="color: #94a3b8;">Prueba seleccionando otra combinación para acumular al menos 3 coincidencias.</small>
                </div>`;
        }
    } catch (error) {
        divResultado.innerHTML = `<p style="color: #f87171;">⚠️ Error de conexión con el backend de Prolog. ¿Está activo el servidor en el puerto 8080?</p>`;
    }
});

// Lógica para procesar la inscripción
document.getElementById('form-inscripcion').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const estudiante = document.getElementById('boleta').value;
    const actividad = document.getElementById('actividad-inscripcion').value;

    const divResultado = document.getElementById('resultado-inscripcion');
    divResultado.style.display = 'block';
    divResultado.innerHTML = '<div class="spinner">Procesando registro único...</div>';

    try {
        const url = new URL(`${BASE_URL}/api/inscribir`);
        url.search = new URLSearchParams({ estudiante, actividad }).toString();

        const respuesta = await fetch(url);
        const datos = await respuesta.json();

        if (datos.status === 'ok') {
            divResultado.innerHTML = `
                <div style="color: #38bdf8; background: #0284c722; padding: 12px; border-radius: 6px; border: 1px solid #0284c7;">
                    ✅ ${datos.mensaje}
                </div>`;
        }
    } catch (error) {
        divResultado.innerHTML = `<p style="color: #f87171;">⚠️ Error al procesar la inscripción con el servidor.</p>`;
    }
});