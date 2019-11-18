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
        private List<Framework> Frameworks = new List<Framework>();
        private int frameworkIndex = 0;

        public MainWindow()
        {
            InitializeComponent();

            //IniciarProlog();
            CambiarEstadoRequisitosHardware();
            LlenarDatos();
            SetEvents();
        }

        private void IniciarProlog()
        {
            if (!PrologEngine.Start(@"files\amigos.pl"))
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
            if (Frameworks.Count == 0)
                return;

            frameworkIndex += direccion;

            // wrap index in framework list size

            if (frameworkIndex >= Frameworks.Count)
                frameworkIndex = 0;

            else if (frameworkIndex <= 0)
                frameworkIndex = Frameworks.Count - 1;

            Framework framework = Frameworks[frameworkIndex];

            // update ui

            tbNombreFramework.Text = framework.Nombre;
            tbDescFramework.Text = framework.Descripcion;
            lvVentajas.ItemsSource = framework.Ventajas;
            lvDesventajas.ItemsSource = framework.Desventajas;
        }

        private void CambiarVisibilidadDetallesFramework()
        {
            bDetallesFramework.Visibility = (bDetallesFramework.Visibility == Visibility.Visible) ? Visibility.Collapsed : Visibility.Visible;
        }

        private void AplicarFiltros()
        {

        }
    }
}
