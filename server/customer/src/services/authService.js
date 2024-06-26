const {getCassClient, getClientOracle} = require('../database/index');
const { FormateData, GeneratePassword, GenerateSalt, GenerateSignature, GenerateRefreshToken, ValidatePassword } = require('../utils');
const bcrypt = require("bcrypt");
const oracledb = require("oracledb");
const redis = require('redis');

const createError = require('http-errors');

class AuthenticationService{
    constructor() {
        console.log('Authentication service');
        this.initializeDB()
    }
    async initializeDB() {

        try {
            this.OracleClient =await getClientOracle();
            console.log("Oracle connected")
        } catch (error) {   
            console.log(error)
        }
    }
    async SignIn(userInputs){

        const { email, password } = userInputs;

        const customerFindQuery = `SELECT * FROM site_user where email_address = :email`;
        try {
            const existingCustomer = await this.OracleClient.execute(customerFindQuery,
                {
                    email: email
                },
                { outFormat: oracledb.OUT_FORMAT_OBJECT });
            
            if(existingCustomer.rows[0]){

                const validPassword = bcrypt.compare(existingCustomer.rows[0].PASSWORD, password);
                if(validPassword){
                    const token = await GenerateSignature(existingCustomer.rows[0].ID);
                    const refreshToken = await GenerateRefreshToken(existingCustomer.rows[0].ID)
                    return FormateData({
                        id: existingCustomer.rows[0].ID, 
                        name: existingCustomer.rows[0].FIRST_NAME + ' ' +existingCustomer.rows[0].LAST_NAME,
                        role: existingCustomer.rows[0].ROLE,
                        accessToken: token,
                        refreshToken: refreshToken
                     });
                }
            }
            throw error()
        } catch (error) {
            
        }

        return FormateData(null);
    }
    async SignUp(userInputs){
        const { email, phone, password, first_name, last_name } = userInputs;

        // create salt
        let salt = await GenerateSalt();

        let userPassword = await GeneratePassword(password, salt);

        const customerCreateQuery = `
            INSERT INTO site_user 
            (email_address, phone_number, password, last_name, first_name) 
            VALUES (:email, :phone, :password, :last_name, :first_name)
            RETURNING id INTO :insertedId`;

        const params = { 
            email: email,
            phone: phone,
            password: userPassword,
            last_name: last_name,
            first_name: first_name,
            insertedId: { type: oracledb.NUMBER, dir: oracledb.BIND_OUT }
        };

        try {
            const result = await this.OracleClient.execute(
                customerCreateQuery,
                params,
                { outFormat: oracledb.OUT_FORMAT_OBJECT });
            
            // The ID of the inserted record is now available in params.insertedId
            const insertedId = result.outBinds.insertedId[0];
    
            console.log("Inserted ID:", insertedId);
    
            // You can then use this ID to fetch the inserted record if needed
            const selectQuery = `
                SELECT * FROM site_user 
                WHERE id = :insertedId`;
    
            const selectParams = { insertedId: insertedId };
    
            const insertedRecord = await this.OracleClient.execute(
                selectQuery,
                selectParams,
                { outFormat: oracledb.OUT_FORMAT_OBJECT });
    
            console.log("Inserted Record:", insertedRecord.rows[0]);
    
            const token = await GenerateSignature({ userId: insertedId });
    
    
            await this.OracleClient.commit(); 
            return FormateData({userId: insertedId, accessToken: token });
        } catch (error) {
            throw error(error)
        }
        // return FormateData({id: 1})
    }
}
module.exports = AuthenticationService