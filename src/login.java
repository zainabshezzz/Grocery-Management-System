
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.swing.JFrame;
import javax.swing.JOptionPane;

/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/GUIForms/JFrame.java to edit this template
 */

/**
 *
 * @author DELL
 */
public class login extends javax.swing.JFrame {
    Connection con = null;
    ResultSet rs;
    PreparedStatement pst;
    public static String username;
    public static int empid;
    public void reset(){
 
    }
    public login() {
        super("login");

        try {
            initComponents();
            con = databaseconnection.connection();
            
            connect();
        } catch (ClassNotFoundException | SQLException ex) {
            Logger.getLogger(login.class.getName()).log(Level.SEVERE, null, ex);
        }


    }
    public void connect() throws ClassNotFoundException, SQLException{
        
        pst=con.prepareStatement("Select * from users");
        //Statement st= con.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,ResultSet.CONCUR_READ_ONLY);
        rs=pst.executeQuery();
    }

    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        login = new javax.swing.JButton();
        jLabel1 = new javax.swing.JLabel();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        getContentPane().setLayout(new org.netbeans.lib.awtextra.AbsoluteLayout());

        login.setBackground(new java.awt.Color(0, 128, 108));
        login.setFont(new java.awt.Font("Segoe UI", 1, 18)); // NOI18N
        login.setForeground(new java.awt.Color(242, 242, 242));
        login.setText("LOGIN");
        login.setBorder(null);
        login.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                loginActionPerformed(evt);
            }
        });
        getContentPane().add(login, new org.netbeans.lib.awtextra.AbsoluteConstraints(490, 450, 190, 60));

        jLabel1.setIcon(new javax.swing.ImageIcon(getClass().getResource("/login.png"))); // NOI18N
        getContentPane().add(jLabel1, new org.netbeans.lib.awtextra.AbsoluteConstraints(0, 0, -1, 790));

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void loginActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_loginActionPerformed
        // TODO add your handling code here:
        JFrame f;  
        f=new JFrame();   
        String name=JOptionPane.showInputDialog(f,"Enter Name:");
        JFrame p;  
        username = name;
        p=new JFrame();   
        String password=JOptionPane.showInputDialog(p,"Enter passward:");
        if (isValidLogin(name, password)) {
            JOptionPane.showMessageDialog(f, "Login successful!");
            setVisible(false);
            new home().setVisible(true);
        } 
        else {
            JOptionPane.showMessageDialog(f, "Invalid login credentials. Please try again.");
        }

    }//GEN-LAST:event_loginActionPerformed
    private boolean isValidLogin(String name, String password) {
        try {
            String query = "SELECT * FROM users WHERE username= ? AND passward= ?";
            pst = con.prepareStatement(query);
            pst.setString(1, name);
            pst.setString(2, password);
            rs = pst.executeQuery();
            if (rs.next()) {
                // Set the empid when login is successful
                empid = rs.getInt("emp_id");
                return true;
            }
        } catch (SQLException e) {
            // Handle database errors
        }
        return false;
}
    
    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        /* Set the Nimbus look and feel */
        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
        /* If Nimbus (introduced in Java SE 6) is not available, stay with the default look and feel.
         * For details see http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html 
         */
        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException ex) {
            java.util.logging.Logger.getLogger(login.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(login.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(login.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(login.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /* Create and display the form */
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                new login().setVisible(true);
            }
        });
    }

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JLabel jLabel1;
    private javax.swing.JButton login;
    // End of variables declaration//GEN-END:variables

}
