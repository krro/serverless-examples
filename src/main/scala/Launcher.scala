package pl.krro

import com.amazonaws.services.lambda.runtime.{Context, RequestHandler}
import scala.collection.immutable.Seq
import scala.beans.BeanProperty

case class Response(@BeanProperty body: String, @BeanProperty statusCode: Int = 200, @BeanProperty headers: Map[String, String] = Map.empty)

class Handler extends RequestHandler[Object, Response] {

  override def handleRequest(input: Object, context: Context): Response = {
    Response("hello world", 200)
  }

}