package modelhelper

import (
	"fmt"
	"koding/db/models"
	"time"

	uuid "github.com/satori/go.uuid"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

const SessionColl = "jSessions"

func GetSession(clientId string) (*models.Session, error) {
	session := new(models.Session)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"clientId": clientId}).One(&session)
	}

	err := Mongo.Run(SessionColl, query)
	if err != nil {
		return nil, fmt.Errorf("sessionID '%s' is not validated; err: %s", clientId, err)
	}

	return session, nil
}

// GetSessionById returns session by its bson id
func GetSessionById(id string) (*models.Session, error) {
	ses := new(models.Session)
	return ses, Mongo.One(SessionColl, id, ses)
}

func GetSessionsByUsername(username string) ([]*models.Session, error) {
	sessions := make([]*models.Session, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"username": username}).All(&sessions)
	}

	err := Mongo.Run(SessionColl, query)
	if err != nil {
		return nil, err
	}

	return sessions, nil
}

func GetSessionFromToken(token string) (*models.Session, error) {
	session := new(models.Session)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"otaToken": token}).One(&session)
	}

	err := Mongo.Run(SessionColl, query)
	if err != nil {
		return nil, fmt.Errorf("otaToken '%s' is not validated; err: %s", token, err)
	}

	return session, nil
}

func RemoveToken(clientId string) error {
	updateData := bson.M{
		"otaToken": "",
	}

	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"clientId": clientId}, bson.M{"$unset": updateData})
	}

	err := Mongo.Run(SessionColl, query)
	if err != nil {
		return fmt.Errorf("failed to remove the ota token for sessionID '%s'; err: %s", clientId, err)
	}

	return nil
}

func UpdateSessionIP(token string, ip string) error {
	updateData := bson.M{
		"clientIP": ip,
	}

	query := func(c *mgo.Collection) error {
		return c.Update(bson.M{"clientId": token}, bson.M{"$set": updateData})
	}

	err := Mongo.Run(SessionColl, query)
	if err != nil {
		return fmt.Errorf("failed to update ip for sessionID '%s'; err: %s", token, err)
	}

	return nil
}

func CreateSession(s *models.Session) error {
	return Mongo.Run(SessionColl, insertQuery(s))
}

func CreateSessionForAccount(username, groupName string) (*models.Session, error) {
	uuid1 := uuid.NewV4()

	session := &models.Session{
		Id:           bson.NewObjectId(),
		ClientId:     uuid1.String(),
		ClientIP:     "127.0.0.1",
		Username:     username,
		GroupName:    groupName,
		SessionBegan: time.Now().UTC(),
		LastAccess:   time.Now().UTC(),
	}

	if err := CreateSession(session); err != nil {
		return nil, err
	}

	return session, nil
}

func GetOneSessionForAccount(username, groupName string) (*models.Session, error) {
	session := &models.Session{}

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{
			"username":  username,
			"groupName": groupName,
		}).One(&session)
	}

	err := Mongo.Run(SessionColl, query)
	if err != nil {
		return nil, err
	}

	return session, nil
}
