using SistemaExperto.Datos;
using SistemaExperto.Prolog;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;

namespace SistemaExperto.Gui.Ventanas
{
    public partial class MainWindow : Window
    {
        private List<Frameworks> frameworks = new List<Frameworks>();
        private int frameworkIndex = 0;

        public MainWindow()
        {
            InitializeComponent();

            IniciarProlog();
            CambiarEstadoRequisitosHardware();
            LlenarDatos();
            SetEvents();
        }

        private void IniciarProlog()
        {
            if (!PrologEngine.Start(@"files\frameworks.pl"))
            {
                MessageBox.Show("Error");
                return;
            }
        }

        private void LlenarDatos()
        {
            var plataformas = new List<string>() { "Todos" };
            EnumList.Plataformas.ForEach(i => plataformas.Add(i.ToString()));
            cbPlataformas.ItemsSource = plataformas;
            cbPlataformas.SelectedIndex = 0;

            var sistemasOperativos = new List<string>() { "Todos" };
            EnumList.SistemasOperativos.ForEach(i => sistemasOperativos.Add(i.ToString()));
            cbSistemasOperativos.ItemsSource = sistemasOperativos;
            cbSistemasOperativos.SelectedIndex = 0;

            var lenguajes = new List<string>() { "Todos" };
            EnumList.LenguajeProgramacion.ForEach(i => lenguajes.Add(i.ToString()));
            cbLenguajes.ItemsSource = lenguajes;
            cbLenguajes.SelectedIndex = 0;

            var tipados1 = new List<string>() { "Todos" };
            EnumList.Tipados1.ForEach(i => tipados1.Add(i.ToString()));
            cbTipados1.ItemsSource = tipados1;
            cbTipados1.SelectedIndex = 0;

            var tipados2 = new List<string>() { "Todos" };
            EnumList.Tipados2.ForEach(i => tipados2.Add(i.ToString()));
            cbTipados2.ItemsSource = tipados2;
            cbTipados2.SelectedIndex = 0;

            var paradigmas = new List<string>() { "Todos" };
            EnumList.Paradigmas.ForEach(i => paradigmas.Add(i.ToString()));
            cbParadigmas.ItemsSource = paradigmas;
            cbParadigmas.SelectedIndex = 0;

            var ladosDesarrollo = new List<string>() { "Todos" };
            EnumList.LadoDesarrollo.ForEach(i => ladosDesarrollo.Add(i.ToString()));
            cbLadosDesarrollo.ItemsSource = ladosDesarrollo;
            cbLadosDesarrollo.SelectedIndex = 0;

            var ides = new List<string>() { "Todos" };
            EnumList.IDEs.ForEach(i => ides.Add(i.ToString()));
            cbIdes.ItemsSource = ides;
            cbIdes.SelectedIndex = 0;

            var cpus = new List<string>() { "Todos" };
            EnumList.Procesadores.ForEach(i => cpus.Add(i.ToString()));
            cbCpu.ItemsSource = cpus;
            cbCpu.SelectedIndex = 0;
        }

        private void SetEvents()
        {
            cbPlataformas.SelectionChanged += (s, e) =>
            {
                string selected = cbPlataformas.SelectedItem.ToString();

                if (selected == "Todos")
                {
                    cbSistemasOperativos.IsEnabled = true;
                    cbLadosDesarrollo.IsEnabled = true;
                }
                else if (selected == Plataforma.Escritorio.ToString() || selected == Plataforma.Movil.ToString())
                {
                    cbSistemasOperativos.IsEnabled = true;
                    cbLadosDesarrollo.IsEnabled = false;
                }
                else if (selected == Plataforma.Web.ToString())
                {
                    cbSistemasOperativos.IsEnabled = false;
                    cbLadosDesarrollo.IsEnabled = true;
                }
            };

            cbRequisitosHardware.Click += (s, e) => CambiarEstadoRequisitosHardware();

            bAplicar.Click += (s, e) => AplicarFiltros();

            bAnterior.Click += (s, e) => CambiarFramework(-1);
            bSiguiente.Click += (s, e) => CambiarFramework(1);
        }

        private void CambiarEstadoRequisitosHardware()
        {
            tbRamMin.IsEnabled = !tbRamMin.IsEnabled;
            tbRamMax.IsEnabled = !tbRamMax.IsEnabled;
            tbEspacioDisco.IsEnabled = !tbEspacioDisco.IsEnabled;
            cbCpu.IsEnabled = !cbCpu.IsEnabled;
        }

        private void CambiarFramework(int direccion)
        {
            if (frameworks.Count == 0)
                return;

            frameworkIndex += direccion;

            // wrap index in framework list size

            if (frameworkIndex >= frameworks.Count)
                frameworkIndex = 0;

            else if (frameworkIndex <= 0)
                frameworkIndex = frameworks.Count - 1;

            Frameworks framework = frameworks[frameworkIndex];

            // actualizar la ui

            tbNombreFramework.Text = framework.Nombre;
            tbDescFramework.Text = framework.Descripcion;
            lvVentajas.ItemsSource = framework.Ventajas;
            lvDesventajas.ItemsSource = framework.Desventajas;
            tbPlataforma.Text = framework.Plataforma;
            tbSistemaOperativo.Text = framework.SistemaOperativo;
            tbLenguaje.Text = String.Join(", ", framework.Lenguajes);
            tbTipado1.Text = framework.Tipado1;
            tbTipado2.Text = String.Join(", ", framework.Tipaado2);
            tbLadoDesarrollo.Text = framework.LadoDesarrollo;
            tbIde.Text = String.Join(", ", framework.Ides);

            tbContador.Text = $"{frameworkIndex + 1}/{frameworks.Count}";
        }

        private void CambiarVisibilidadDetallesFramework()
        {
            bDetallesFramework.Visibility = (bDetallesFramework.Visibility == Visibility.Visible) ? Visibility.Collapsed : Visibility.Visible;
        }

        private void AplicarFiltros()
        {
            // obtener filtros

            string plataforma = cbPlataformas.SelectedItem.ToString();
            string sistemaOperativo = cbSistemasOperativos.SelectedItem.ToString();
            string lenguaje = cbLenguajes.SelectedItem.ToString();
            string tipado1 = cbTipados1.SelectedItem.ToString();
            string tipado2 = cbTipados2.SelectedItem.ToString();
            string paradigma = cbParadigmas.SelectedItem.ToString();
            string ladoDesarrollo = cbLadosDesarrollo.SelectedItem.ToString();
            string ide = cbIdes.SelectedItem.ToString();
            string ram = tbRam.Text;
            string espacio = tbEspacio.Text;
            string cpu = tbCpu.Text;

            // normalizar filtros (para que puedan usarse en prolog)

            /*plataforma = NormalizarFiltro(plataforma);
            sistemaOperativo = NormalizarFiltro(sistemaOperativo);
            lenguaje = NormalizarFiltro(lenguaje);
            tipado1 = NormalizarFiltro(tipado1);
            tipado2 = NormalizarFiltro(tipado2);
            paradigma = NormalizarFiltro(paradigma);
            ladoDesarrollo = NormalizarFiltro(ladoDesarrollo);
            ide = NormalizarFiltro(ide);
            ram = NormalizarFiltro(ram);
            espacio = NormalizarFiltro(espacio);
            cpu = NormalizarFiltro(cpu);*/

            // construir consulta para obtener los nombres de los frameworks

            var queries = new List<string>()
            {
                $"plataforma(X, {plataforma})",
                $"sistema_operativo(X, {sistemaOperativo})",
                $"lenguaje(X, {lenguaje})",
                $"tipado1(X, {tipado1})",
                $"tipado2(X, {tipado2})",
                $"paradigma(X, {paradigma})",
                $"lado_desarrollo(X, {ladoDesarrollo})",
                $"ide(X, {ide})",
            };

            string query = new StringBuilder().Append(String.Join(" , ", queries)).Append('.').ToString();

            // procesar la consulta para obtener los nombres de los frameworks

            frameworks.Clear();
            var nombresFrameworks = new List<string>();

            QueryProcessor.ProcessForResults(query).ForEach(result =>
            {
                foreach (var i in result)
                {
                    nombresFrameworks.Add(i.Value);
                }
            });

            // procesar consultas para obtener los detalles de los frameworks

            nombresFrameworks.ForEach(nombre =>
            {
                frameworks.Add(new Frameworks()
                {
                    Nombre = DenormalizarFiltro(nombre),
                    Descripcion = QueryProcessor.ProcessForString($"descripcion({nombre}, X)"),
                    Ventajas = QueryProcessor.ProcessForList($"ventajas({nombre}, X)"),
                    Desventajas = QueryProcessor.ProcessForList($"desventajas({nombre}, X)"),
                    Plataforma = QueryProcessor.ProcessForString($"plataforma({nombre}, X)"),
                    SistemaOperativo = QueryProcessor.ProcessForString($"sistema_operativo({nombre}, X)"),
                    Lenguajes = QueryProcessor.ProcessForList($"lenguaje({nombre}, X)"),
                    Tipado1 = QueryProcessor.ProcessForString($"tipado1({nombre}, X)"),
                    Tipaado2 = QueryProcessor.ProcessForList($"tipado2({nombre}, X)"),
                    Paradigmas = QueryProcessor.ProcessForList($"paradigma({nombre}, X)"),
                    LadoDesarrollo = QueryProcessor.ProcessForString($"lado_desarrollo({nombre}, X)"),
                    Ides = QueryProcessor.ProcessForList($"ide({nombre}, X)"),
                });
            });

            // mostrar los frameworks encontrados
            frameworkIndex = 0;
            CambiarFramework(0);
        }

        private string NormalizarFiltro(string filtro)
        {
            return filtro.ToLower().Replace(' ', '_');
        }

        private string DenormalizarFiltro(string filtro)
        {
            string[] words = filtro.Split('_');

            for (int i = 0; i < words.Length; i++)
            {
                string currentWord = words[i];

                // hola -> Hola
                currentWord = new StringBuilder()
                    .Append(currentWord[0].ToString().ToUpper())
                    .Append(currentWord.Substring(1))
                    .ToString();

                words[i] = currentWord;
            }

            return String.Join(" ", words);
        }
    }
}
